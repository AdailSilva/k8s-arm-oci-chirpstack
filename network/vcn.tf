# =============================================================================
# VCN — recursos nativos (substituem o módulo oracle-terraform-modules/vcn/oci)
# =============================================================================
#
# Por que não usamos mais o módulo de registry?
#   O módulo oracle-terraform-modules/vcn/oci expõe no output
#   "ig_route_all_attributes" o objeto INTEIRO do oci_core_route_table,
#   incluindo o atributo computado route_rules[*].cidr_block, que está
#   DEPRECIADO no provider OCI. A partir do OpenTofu 1.10 isso gera o warning
#   "Value derived from a deprecated source" em todo plan/apply, mesmo o
#   módulo usando corretamente "destination" — e o warning existe também na
#   versão mais recente do módulo (o output continua lá).
#
#   Declarando os recursos diretamente, o warning desaparece e o projeto
#   deixa de depender de um módulo externo para 4 recursos simples.
#
# Migração SEM recriar nada:
#   Os blocos "moved" no final deste arquivo transferem os recursos que hoje
#   estão no state em module.network.module.vcn.* para os novos endereços.
#   O plan deve mostrar apenas "has moved to" — nenhum destroy/create.
#   Os atributos (display_name, freeform_tags, descrições das rotas) foram
#   mantidos idênticos aos que o módulo v3.1.0 gerava, para não haver diff.
# =============================================================================

locals {
  anywhere = "0.0.0.0/0"

  # Mesmas tags que o módulo v3.1.0 aplicava por padrão — mantidas para que o
  # plan não mostre update in-place. Podem ser alteradas depois, se desejar.
  vcn_freeform_tags = {
    terraformed = "Please do not edit manually"
    module      = "oracle-terraform-modules/vcn/oci"
  }
}

# -----------------------------------------------------------------------------
# VCN
# -----------------------------------------------------------------------------
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "vcn"
  dns_label      = var.vcn_dns_label
  is_ipv6enabled = false
  freeform_tags  = local.vcn_freeform_tags
}

# Default Security List da VCN sem nenhuma regra (lockdown).
# Equivale ao comportamento padrão do módulo (lockdown_default_seclist = true).
# As subnets usam Security Lists próprias (public-subnet.tf / private-subnet.tf).
resource "oci_core_default_security_list" "lockdown" {
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
}

# -----------------------------------------------------------------------------
# Internet Gateway + Route Table (subnet pública)
# -----------------------------------------------------------------------------
resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "internet-gateway"
  freeform_tags  = local.vcn_freeform_tags
}

resource "oci_core_route_table" "ig" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "internet-route"
  freeform_tags  = local.vcn_freeform_tags

  route_rules {
    # Usa "destination" + "destination_type" — nunca o "cidr_block" depreciado.
    destination       = local.anywhere
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.ig.id
    description       = "Terraformed - Auto-generated at Internet Gateway creation: Internet Gateway as default gateway"
  }
}

# -----------------------------------------------------------------------------
# NAT Gateway + Service Gateway + Route Table (somente com subnet privada)
# -----------------------------------------------------------------------------
data "oci_core_services" "all_oci_services" {
  count = var.provision_private_subnet ? 1 : 0

  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "service_gateway" {
  count          = var.provision_private_subnet ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "service-gateway"
  freeform_tags  = local.vcn_freeform_tags

  services {
    service_id = data.oci_core_services.all_oci_services[0].services[0].id
  }
}

resource "oci_core_nat_gateway" "nat_gateway" {
  count          = var.provision_private_subnet ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "nat-gateway"
  freeform_tags  = local.vcn_freeform_tags
}

resource "oci_core_route_table" "nat" {
  count          = var.provision_private_subnet ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "nat-route"
  freeform_tags  = local.vcn_freeform_tags

  route_rules {
    destination       = local.anywhere
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway[0].id
    description       = "Terraformed - Auto-generated at NAT Gateway creation: NAT Gateway as default gateway"
  }

  route_rules {
    destination       = data.oci_core_services.all_oci_services[0].services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway[0].id
    description       = "Terraformed - Auto-generated at Service Gateway creation: All Services in region to Service Gateway"
  }
}

# -----------------------------------------------------------------------------
# DHCP
# -----------------------------------------------------------------------------
resource "oci_core_dhcp_options" "dhcp_options" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
}

# =============================================================================
# Migração de state: module.vcn.* → recursos nativos
# (podem ser removidos depois que o apply com a migração for concluído)
# =============================================================================
moved {
  from = module.vcn.oci_core_vcn.vcn
  to   = oci_core_vcn.vcn
}

moved {
  from = module.vcn.oci_core_default_security_list.lockdown[0]
  to   = oci_core_default_security_list.lockdown
}

moved {
  from = module.vcn.oci_core_internet_gateway.ig[0]
  to   = oci_core_internet_gateway.ig
}

moved {
  from = module.vcn.oci_core_route_table.ig[0]
  to   = oci_core_route_table.ig
}

moved {
  from = module.vcn.oci_core_service_gateway.service_gateway
  to   = oci_core_service_gateway.service_gateway
}

moved {
  from = module.vcn.oci_core_nat_gateway.nat_gateway
  to   = oci_core_nat_gateway.nat_gateway
}

moved {
  from = module.vcn.oci_core_route_table.nat
  to   = oci_core_route_table.nat
}
