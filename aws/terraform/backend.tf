terraform {
  backend "remote" {
    organization = "sandbox-01"

    workspaces {
      name = "aws-sandbox"
    }
  }
}
