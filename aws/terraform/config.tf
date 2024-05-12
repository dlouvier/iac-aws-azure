terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.49.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.13.2"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "remote" {
    organization = "sandbox-01"

    workspaces {
      name = "aws-sandbox"
    }
  }
}

data "aws_eks_cluster" "default" {
  depends_on = [module.eks.cluster_name]
  name       = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "default" {
  depends_on = [module.eks.cluster_name]
  name       = module.eks.cluster_name
}

provider "dns" {
  update {
    server = "1.1.1.1"
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}
