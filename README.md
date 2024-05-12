# iac-aws-azure

This project demos how to deploy a "Hello World" application in Kubernetes running in AWS & Azure clouds. In addition, the application is exposed to the internet via an Application Load Balancer (L7).

## Introduction

This repository contains three important directories: [aws](./aws/), [azure](./azure/), and [helm](./helm/), which contain the respective Terraform manifests for each cloud and two reusable charts.

## Terraform

In order to run the current Terraform projects, it is necessary to configure Terraform Cloud as backend remote storage. If you want to use `local` or some other provider, adjust the configuration in each `backend.tf` file inside the aws or azure folder.

## AWS

For AWS, it has been configured to use [Dynamic Provider Credentials](https://aws.amazon.com/blogs/apn/simplify-and-secure-terraform-workflows-on-aws-with-dynamic-provider-credentials/), so no static secrets are stored anywhere, and the `PLAN` and `APPLY` actions of Terraform run in Terraform Cloud.

In [./aws/init](./aws/init/) you can run `task` (you need to have installed [Taskfile](https://taskfile.dev/)) to provision the additional identity provider but first replace "<AMAZON_ACCOUNT_ID>" in [dynamic-creds.json](./aws/init/dynamic-creds.json) file.

To provide access to yourself (so you can use `kubectl`), run `export TF_VAR_admin_user_arn="arn:aws:iam::<AMAZON_ACCOUNT_ID>:user/<AMAZON_USER>"` then you can use `aws eks update-kubeconfig --region eu-central-1 --name sandbox-eks-cluster` to obtain the credentials and use `kubectl` locally.

## Azure

For Azure I wasn't able to create [Dynamic credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration) due to my Azure account permissions, and that also complicated things to be able to create a Service Principal, so I wasn't able to run the `PLAN` & `APPLY` from Terraform Cloud (I've disabled this for this workspace) so everything needs to be running locally.

Before starting, ensure you ran `az login`.

**Note:**
The `helm` charts deployment may also fail, try using `export KUBE_CONFIG_PATH=~/.kube/config` before running `terraform plan or apply`.

Once the cluster is provisioned, use:

```
az aks list
az aks show
az aks get-credentials --admin --name <AKS_CLUSTER_NAME> --resource-group <RESOURCE_GROUP_NAME>
```

and `kubectl` should work ;)

## Terraform

The rest of the resources (VPC, EKS, ALB, Helm deployments,...) are handled via Terraform.
The manifest files are available at [./aws/terraform](./aws/terraform/).

The total provision time is around 10-15 minutes.

After running `terraform apply`, you should see a message like: _"The URL to access the hello-world application is http://<SOME-IP>.nip.io"_.

**Note:** If this URL is malformed, re-run after 4-5 minutes, especially in AWS, the DNS takes some time to propagate so it cannot create the URL correctly.

([what's nip.io?](https://nip.io/))

## Others questions

### Why `default-ingress` chart?

The `default-ingress` chart is used because the Application Load Balancer is provisioned when the first Ingress is created. This load balancer can be later reused by multiple "hostnames" or ingresses, so the `default-ingress` chart creates the first one and then it can be reused.

### Security

The security policies in this exercise are intentionally permissive for demonstration purposes. However, in a real-world scenario, it is important to have more restrictive security policies in place.

```

```
