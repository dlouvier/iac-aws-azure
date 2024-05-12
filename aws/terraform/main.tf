

data "aws_availability_zones" "available" {}

locals {
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr = "10.0.0.0/16"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"
  name    = "sandbox-vpc"

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  create_egress_only_igw = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.10"

  cluster_name    = "sandbox-eks-cluster"
  cluster_version = "1.29"

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  access_entries = {
    dlouvier = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::123456789012:user/dlouvier" # Needs to be updated with your own ARN

      policy_associations = {
        myself = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    t3small = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.small"]
      capacity_type  = "SPOT"

      create_iam_role          = true
      iam_role_name            = "eks-sandbox-node"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group role"

      iam_role_additional_policies = {
        ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess" # Too permissive but demonstration only
        AmazonEC2FullAccess            = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"            # Adding an additional role here, requires to rollout again the node pool
        AWSWAFFullAccess               = "arn:aws:iam::aws:policy/AWSWAFFullAccess"               # Required to deploy the ALB :(
      }
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.default.token
  }
}

resource "helm_release" "aws_lb" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

resource "helm_release" "default-ingress" {
  depends_on = [helm_release.aws_lb]
  name       = "default-ingress"
  chart      = "../../helm/default-ingress"
  namespace  = "default"
  version    = "0.1.0"

  set {
    name  = "cloud"
    value = "aws"
  }
}

data "kubernetes_ingress_v1" "lb_hostname" {
  depends_on = [helm_release.default-ingress]
  metadata {
    name      = "default-ingress"
    namespace = "default"
  }
}

data "dns_a_record_set" "lb_address_ip" {
  depends_on = [data.kubernetes_ingress_v1.alb_hostname]
  host       = data.kubernetes_ingress_v1.lb_hostname.status.0.load_balancer.0.ingress.0.hostname
}

locals {
  ingress_hostname = "${data.dns_a_record_set.lb_address_ip.addrs[0]}.nip.io"
}

resource "helm_release" "hello-world" {
  depends_on = [data.dns_a_record_set.alb_address_ip]
  name       = "hello-world"
  chart      = "../../helm/hello-world"
  namespace  = "default"
  version    = "0.1.0"

  set {
    name  = "hostname"
    value = "${local.ingress_hostname}.nip.io"
  }

  set {
    name  = "cloud"
    value = "aws"
  }
}

output "url" {
  value = "The URL to access to the hello-world application is http://${local.ingress_hostname}"
}
