terraform {
  cloud {
    organization = "sandbox-01"

    workspaces {
      name = "azure-sandbox"
    }
  }
}
