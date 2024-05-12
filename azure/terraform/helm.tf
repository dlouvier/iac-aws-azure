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


