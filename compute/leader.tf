# Busca a build mais recente da imagem pelo prefixo (ex.: "Canonical-Ubuntu-24.04-aarch64").
# A OCI remove builds antigas periodicamente; fixar a data no nome quebra o plan.
data "oci_core_images" "leader" {
  compartment_id   = var.compartment_id
  operating_system = "Canonical Ubuntu"
  shape            = var.leader.shape
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"

  filter {
    name   = "display_name"
    values = ["^${var.leader.image}-[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}-[0-9]+$"]
    regex  = true
  }
}

data "oci_core_subnet" "leader" {
  subnet_id = var.leader.subnet_id
}

data "oci_core_vcn" "vcn" {
  vcn_id = data.oci_core_subnet.leader.vcn_id
}

resource "oci_core_instance" "leader" {
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain

  display_name = var.leader.hostname

  shape = var.leader.shape
  shape_config {
    ocpus         = var.leader.ocpus
    memory_in_gbs = var.leader.memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.leader.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    assign_public_ip          = var.leader.assign_public_ip
    subnet_id                 = var.leader.subnet_id
    assign_private_dns_record = true
    hostname_label            = var.leader.hostname
  }

  # metadata = {
  #   ssh_authorized_keys = file(var.ssh_key_pub_path)
  # }
  # metadata = {
  #   ssh_authorized_keys = trimspace(file("/home/adailsilva/.ssh/id_ed25519.pub"))
  # }
  metadata = {
    ssh_authorized_keys = trimspace(file(var.ssh_key_pub_path))
  }

  lifecycle {
    prevent_destroy = true
    # Evita recriar a instância quando o data source passar a retornar uma build mais nova da imagem.
    ignore_changes  = [source_details[0].source_id]
  }
}

locals {
  leader_fqdn = "${var.leader.hostname}.${data.oci_core_subnet.leader.dns_label}.${data.oci_core_vcn.vcn.dns_label}.oraclevcn.com"
}


# Load Balancer - SSH to leader

resource "oci_network_load_balancer_backend_set" "leader_tcp_22" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "leader_tcp_22"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
  health_checker {
    protocol = "TCP"
    port     = 22
  }
}

resource "oci_network_load_balancer_backend" "leader_tcp_22" {
  backend_set_name         = oci_network_load_balancer_backend_set.leader_tcp_22.name
  network_load_balancer_id = var.load_balancer_id
  name                     = "leader_tcp_22"
  port                     = 22
  target_id                = oci_core_instance.leader.id

  depends_on = [
    oci_network_load_balancer_backend_set.leader_tcp_22
  ]
}

resource "oci_network_load_balancer_listener" "leader_tcp_22" {
  default_backend_set_name = oci_network_load_balancer_backend_set.leader_tcp_22.name
  name                     = "leader_tcp_22"
  network_load_balancer_id = var.load_balancer_id
  port                     = 22
  protocol                 = "TCP"

  depends_on = [
    oci_network_load_balancer_backend.leader_tcp_22
  ]
}