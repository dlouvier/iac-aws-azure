# iac-aws-azure

## Demo project to deploy a Kubernetes application in AWS & Azure Cloud

### AWS

#### Initial configuration

To prevent any access key leak, a [Dynamic Provider Credentials](https://aws.amazon.com/blogs/apn/simplify-and-secure-terraform-workflows-on-aws-with-dynamic-provider-credentials/) has been configured.

[This page](https://aws.amazon.com/blogs/apn/simplify-and-secure-terraform-workflows-on-aws-with-dynamic-provider-credentials/) shows how to configure automatically but I've prepared a _Taskfile_ which can do it for you:

```
$ cd ./aws/init/
$ task
```

#### Terraform

The rest of the resources (VPC, EKS, ALB, Helm deployments,...) are handle via Terraform.

The manifest files are available are [./aws/terraform](./aws/terraform/)

#### Getting the Public DNS
