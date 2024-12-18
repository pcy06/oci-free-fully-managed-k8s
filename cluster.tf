resource "oci_containerengine_cluster" "k8s-cluster" {
  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }
  compartment_id = var.compartment_ocid
  endpoint_config {
    is_public_ip_enabled = "false"
    subnet_id            = oci_core_subnet.k8s-endpoint-subnet.id
  }
  kubernetes_version = "v${var.kubernetes_version}"
  name               = "k8s-cluster"
  options {
    service_lb_subnet_ids = [oci_core_subnet.k8s-load-balancer-subnet.id]
  }
  type   = "BASIC_CLUSTER"
  vcn_id = oci_core_vcn.k8s-vcn.id
}

resource "oci_containerengine_node_pool" "k8s-node-pool" {
  cluster_id     = oci_containerengine_cluster.k8s-cluster.id
  compartment_id = var.compartment_ocid
  initial_node_labels {
    key   = "name"
    value = "k8s-nodes-pool"
  }
  name = "k8s-nodes-pool"
  node_config_details {
    is_pv_encryption_in_transit_enabled = "true"
    node_pool_pod_network_option_details {
      cni_type          = "OCI_VCN_IP_NATIVE"
      max_pods_per_node = "31"
      // Maximum number of Pods per node = MIN((Number of VNICs - 1) * 31 ), 110)
      // VM.Standard.A1.Flex: 1 VNIC per OCPU (2 OCPUs = 2 VNICs = Max 31 Pods per node)
      pod_subnet_ids = [oci_core_subnet.k8s-pods-subnet.id]
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.regional_ads.availability_domains.0.name
      subnet_id           = oci_core_subnet.k8s-nodes-subnet.id
    }
    size = "2"
  }
  node_eviction_node_pool_settings {
    eviction_grace_duration              = "PT1H"
    is_force_delete_after_grace_duration = "false"
  }
  kubernetes_version = "v${var.kubernetes_version}"
  node_shape         = "VM.Standard.A1.Flex"
  node_shape_config {
    memory_in_gbs = "12"
    ocpus         = "2"
  }
  node_source_details {
    boot_volume_size_in_gbs = "75"
    image_id                = local.oke_node_image_id
    source_type             = "IMAGE"
  }
  ssh_public_key = tls_private_key.ssh-key.public_key_openssh
}
