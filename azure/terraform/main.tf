# Generate random resource group name
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

resource "random_pet" "azurerm_kubernetes_cluster_name" {
  prefix = "cluster"
}

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.rg.location
  name                = random_pet.azurerm_kubernetes_cluster_name.id
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = random_pet.azurerm_kubernetes_cluster_dns_prefix.id

  ingress_application_gateway {
    gateway_name = "myApplicationGateway"
    subnet_cidr  = "10.225.0.0/16"
  }

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "standard_a2_v2"
    node_count = var.node_count
    upgrade_settings {
      max_surge = "10%"
    }
  }
  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = azapi_resource_action.ssh_public_key_gen.output.publicKey
    }
  }
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
}

resource "helm_release" "default_ingress" {
  depends_on = [azurerm_kubernetes_cluster.k8s]
  name       = "default-ingress"
  chart      = "../../helm/default-ingress"
  namespace  = "default"
  version    = "0.1.0"

  set {
    name  = "cloud"
    value = "azure"
  }
}

data "kubernetes_ingress_v1" "lb_hostname" {
  depends_on = [helm_release.default_ingress]
  metadata {
    name      = "default-ingress"
    namespace = "default"
  }
}

data "dns_a_record_set" "lb_address_ip" {
  depends_on = [data.kubernetes_ingress_v1.lb_hostname]
  host       = data.kubernetes_ingress_v1.lb_hostname.status.0.load_balancer.0.ingress.0.ip
}

locals {
  ingress_hostname = "${data.dns_a_record_set.lb_address_ip.addrs[0]}.nip.io"
}

resource "helm_release" "hello-world" {
  depends_on = [data.dns_a_record_set.lb_address_ip]
  name       = "hello-world"
  chart      = "../../helm/hello-world"
  namespace  = "default"
  version    = "0.1.0"

  set {
    name  = "hostname"
    value = local.ingress_hostname
  }

  set {
    name  = "cloud"
    value = "azure"
  }
}

output "url" {
  value = "The URL to access to the hello-world application is http://${local.ingress_hostname}"
}


