terraform {
  required_providers {
    digitalocean = {
      source = "terraform-providers/digitalocean"
    }
    local = {
      source = "hashicorp/local"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}
