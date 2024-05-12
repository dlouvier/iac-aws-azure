variable "TFC_AWS_PROVIDER_AUTH" {
  default = ""
}

variable "TFC_AWS_RUN_ROLE_ARN" {
  default = ""
}

variable "admin_user_arn" {
  default = {
    dlouvier = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::123456789012:user/dlouvier"

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


