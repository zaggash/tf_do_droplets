# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_tag" "prefix" {
  name = var.prefix
}

resource "digitalocean_droplet" "droplet" {
  count              = var.nb_of_nodes
  image              = var.image_server
  name               = "${var.prefix}-droplet-${count.index}"
  private_networking = true
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


resource "digitalocean_record" "a" {
  count  = var.nb_of_nodes
  domain = var.domain
  type   = "A"
  name   = element(digitalocean_droplet.droplet.*.name, count.index)
  value  = element(digitalocean_droplet.droplet.*.ipv4_address, count.index)
  ttl    = 30
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
  value = [digitalocean_record.a.*.fqdn]
}


