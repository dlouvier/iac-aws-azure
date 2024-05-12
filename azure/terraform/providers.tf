terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "1.13.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.103.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.2"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
  }

}

provider "azurerm" {
  features {}
}

data "azurerm_kubernetes_cluster" "default" {
  name                = azurerm_kubernetes_cluster.k8s.name
  resource_group_name = azurerm_kubernetes_cluster.k8s.resource_group_name
}

provider "kubernetes" {
  alias                  = "aks"
  host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }
}
