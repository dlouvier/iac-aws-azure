# iac-aws-azure

This project demos how to deploy a "Hello World" application in Kubernetes running in AWS & Azure clouds. In addition the application is exposed to the internet via an Application Load Balancer (L7).

## Introduction

This repository contains three important directories: [aws](./aws/), [azure](./azure/) and [helm](./helm/) which contains the respective terraform manifest for each cloud and two reusable charts.

## Terraform

In order to run the current terraform projects, it is necessary to configure Terraform Cloud as backend remote storage. If you want to use `local` or some other provider, adjust the configuration in each `backend.tf` file inside of aws or azure folder.

## Authentification

For AWS it has been configured to use [Dynamic Provider Credentials](https://aws.amazon.com/blogs/apn/simplify-and-secure-terraform-workflows-on-aws-with-dynamic-provider-credentials/) so not static secrets are store nowhere and the `PLAN` and `APPLY` actions of terraform runs in Terraform Cloud. For Azure I wasn't able to configure due limitations in my account (I need higher priviledges in the organisation), so before running, ensure `az login` is correctly configured.

## AWS

As mentioned before, [Dynamic Provider Credentials](https://aws.amazon.com/blogs/apn/simplify-and-secure-terraform-workflows-on-aws-with-dynamic-provider-credentials/) is configured but it can easily provisioned running a Taskfile I provided (first we need to authenficated with AWS CLI)

```
$ cd ./aws/init/
$ task
```

## Azure

For Azure I wasn't able to create [Dynamic credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration) due my Azure account permissions and that also complicated things to be able to create a Service Principal, so I wasn't able to run the `PLAN` & `APPLY` from Terraform Cloud (I've disabled this for this workspace) so entirely everything needs to be running locally.

Before starting ensure you ran `az login`

## Terraform

The rest of the resources (VPC, EKS, ALB, Helm deployments,...) are handle via Terraform.
The manifest files are available are [./aws/terraform](./aws/terraform/)

The total provision time is around 10-15min.

After running `terraform apply` you should see a message like: _"The URL to access to the hello-world application is http://some-ip.nip.io"_

**Note:** If this URL is malformed, re-run after 4-5 minutes, specially in AWS, the DNS takes some time to propagate so it cannot create the URL correctly.

([what's nip.io?](https://nip.io/))
