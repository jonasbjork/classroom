
provider "hcloud" {
  token = var.hcloud_token
}

variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Namn på SSH-nyckeln i Hetzner"
  type        = string
  default     = "my-ssh-key"
}

variable "public_key_path" {
  description = "Sökväg till den publika SSH-nyckeln"
  type        = string
  default     = "./ssh/my-ssh-key.pub"
}

variable "server_type" {
  description = "typ av server"
  type        = string
  default     = "cx23"
}

variable "image" {
  description = "vilken dist?"
  type        = string
  default     = "centos-stream-9"
}

variable "location" {
  description = "Vilket datacenter?"
  type        = string
  default     = "fsn1"
}

variable "domain_name" {
  description = "domain name"
  type        = string
  default     = "example.com"
}

# NYTT: Här definierar du vilka servrar som ska finnas
# Lägg till eller ta bort nycklar här för att skapa/radera enskilda servrar
variable "servers" {
  description = "Map med servrar som ska skapas. Nyckeln blir hostname-del (t.ex. server-01, db-01, jump-01)"
  type        = map(object({
    name   = string           # det fulla hostname-prefixet, t.ex. "web-01" eller "jump"
    type   = optional(string) # override server_type om du vill
    labels = optional(map(string))
  }))
  default = {
    "server-01" = { name = "server-01" }
    "server-02"      = { name = "server-02" }
    # Lägg till eller ta bort rader här – Terraform skapar/raderar bara det som ändrats
  }
}

data "local_file" "public_key" {
  filename = var.public_key_path
}

resource "hcloud_ssh_key" "default" {
  name       = var.ssh_key_name
  public_key = data.local_file.public_key.content
}

resource "hcloud_zone" "domain" {
  name = var.domain_name
  ttl  = 600
  mode = "primary"
}

resource "hcloud_firewall" "firewall" {
  name = "lab-firewall"

  # SSH-åtkomst
  rule {
    direction       = "in"
    protocol        = "tcp"
    port            = "22"
    source_ips      = ["0.0.0.0/0", "::/0"]
  }
  # HTTP-trafik
  rule {
    direction       = "in"
    protocol        = "tcp"
    port            = "80"
    source_ips      = ["0.0.0.0/0", "::/0"]
  }
  # HTTPS-trafik
  rule {
    direction       = "in"
    protocol        = "tcp"
    port            = "443"
    source_ips      = ["0.0.0.0/0", "::/0"]
  }
  # Alternativ HTTP-port
  rule {
    direction       = "in"
    protocol        = "tcp"
    port            = "8080"
    source_ips      = ["0.0.0.0/0", "::/0"]
  }
}

# Huvudresurs – en server per nyckel i var.servers
resource "hcloud_server" "servers" {
  for_each = var.servers

  name        = each.value.name
  server_type = coalesce(each.value.type, var.server_type)
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.name]
  firewall_ids = [hcloud_firewall.firewall.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  labels = merge(
    { environment = "lab" },
    lookup(each.value, "labels", {})
  )
}

# A-record för varje server
resource "hcloud_zone_rrset" "a_records" {
  for_each = hcloud_server.servers

  zone = hcloud_zone.domain.name
  type = "A"
  name = each.value.name # t.ex. server-01
  ttl  = 600

  records = [
    { value = each.value.ipv4_address }
  ]
}

# Uppdaterat inventory som fungerar med for_each
resource "local_file" "inventory" {
  content = templatefile("templates/inventory.tpl", {
    servers   = [for s in hcloud_server.servers : "${s.name}.${var.domain_name}"]
    server_ip = [for s in hcloud_server.servers : s.ipv4_address]
  })
  filename = "ansible/inventory"
}

