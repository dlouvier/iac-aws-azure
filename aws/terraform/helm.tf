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
  version    = "1.8.1"

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
  depends_on = [data.kubernetes_ingress_v1.lb_hostname]
  host       = data.kubernetes_ingress_v1.lb_hostname.status.0.load_balancer.0.ingress.0.hostname
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
