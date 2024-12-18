data "oci_containerengine_node_pool_option" "node_pool_options" {
  node_pool_option_id = oci_containerengine_cluster.k8s-cluster.id
  compartment_id      = var.compartment_ocid
}

locals {
  oke_node_image_id = [
    for source in data.oci_containerengine_node_pool_option.node_pool_options.sources : source.image_id
    if can(regex("^Oracle-Linux-.*-aarch64-.*-OKE-${var.kubernetes_version}-.*$", source.source_name))
  ][0]
}

data "oci_core_images" "ubuntu-24-04" {
  compartment_id   = var.compartment_ocid
  operating_system = "Canonical Ubuntu"
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-24.04-([\\.0-9-]+)$"]
    regex  = true
  }
}
