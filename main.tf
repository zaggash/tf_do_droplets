# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_tag" "prefix" {
  name = var.prefix
}

locals {
  droplets_fqdn = formatlist("%s.%s.sslip.io", digitalocean_droplet.droplet.*.name, digitalocean_droplet.droplet.*.ipv4_address)
}

resource "digitalocean_vpc" "droplets-network" {
  name        = "${var.prefix}-droplets-vpc"
  region      = var.region_server
}

resource "digitalocean_droplet" "droplet" {
  count              = var.nb_of_nodes
  image              = var.image_server
  name               = "${var.prefix}-droplet-${count.index}"
  vpc_uuid           = digitalocean_vpc.droplets-network.id
  region             = var.region_server
  size               = var.size
  user_data          = data.template_file.userdata_droplet.rendered
  ssh_keys           = var.ssh_keys
  tags               = [digitalocean_tag.prefix.name]
}

data "template_file" "userdata_droplet" {
  template = file("files/userdata_droplet")
  vars = {
    docker_version = var.docker_version
  }
}

resource "local_file" "ssh_config" {
  content = templatefile("${path.module}/files/ssh_config_template", {
    prefix = var.prefix
    server = [for node in digitalocean_droplet.droplet : node.ipv4_address],
    user   = var.user,
  })
  filename = "${path.module}/ssh_config"
}

# Output the FQDN for the record
output "fqdn" {
  value = local.droplets_fqdn
}

output "private-ip" {
  value = [digitalocean_droplet.droplet.*.ipv4_address_private]
}

output "public-ip" {
  value = [digitalocean_droplet.droplet.*.ipv4_address]
}
