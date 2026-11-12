# Busca a build mais recente da imagem pelo prefixo (ex.: "Canonical-Ubuntu-24.04-aarch64").
# A OCI remove builds antigas periodicamente; fixar a data no nome quebra o plan.
data "oci_core_images" "workers" {
  compartment_id   = var.compartment_id
  operating_system = "Canonical Ubuntu"
  shape            = var.workers.shape
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"

  filter {
    name   = "display_name"
    values = ["^${var.workers.image}-[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}-[0-9]+$"]
    regex  = true
  }
}

resource "oci_core_instance" "worker" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  count        = var.workers.count
  display_name = "${var.workers.base_hostname}-${count.index}"

  shape = var.workers.shape
  shape_config {
    ocpus         = var.workers.ocpus
    memory_in_gbs = var.workers.memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.workers.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    assign_public_ip          = var.workers.assign_public_ip
    subnet_id                 = var.workers.subnet_id
    assign_private_dns_record = true
    hostname_label            = "${var.workers.base_hostname}-${count.index}"
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
