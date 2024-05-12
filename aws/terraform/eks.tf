

data "aws_availability_zones" "available" {}

locals {
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr = "10.0.0.0/16"
  admin_user = var.admin_user_arn ? {} : {
    default = {
      dlouvier = {
        kubernetes_groups = []
        principal_arn     = "${var.admin_user_arn}"

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
  }
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

  access_entries = local.admin_user

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
