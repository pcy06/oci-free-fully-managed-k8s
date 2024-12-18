
resource "oci_core_instance" "k8s-bastion" {
  display_name = "k8s-bastion"
  shape        = "VM.Standard.E2.1.Micro"

  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }

  availability_domain = data.oci_identity_availability_domains.regional_ads.availability_domains.0.name
  compartment_id      = var.compartment_ocid

  create_vnic_details {
    assign_ipv6ip             = false
    assign_private_dns_record = true
    assign_public_ip          = false
    display_name              = "k8s-bastion-vnic"
    subnet_id                 = oci_core_subnet.k8s-bastion-subnet.id
  }
  source_details {
    boot_volume_size_in_gbs = "50"
    boot_volume_vpus_per_gb = "10"
    source_id               = data.oci_core_images.ubuntu-24-04.images.0.id
    source_type             = "image"
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.ssh-key.public_key_openssh
    user_data = base64encode(
      "#!/bin/bash\nCLUSTER_ID=${oci_containerengine_cluster.k8s-cluster.id};\nREGION=${var.region};\n${file("./scripts/bastion-init.sh")}"
    )
  }
}

data "oci_core_vnic_attachments" "k8s-bastion-vnic-attachments" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.k8s-bastion.id
}

data "oci_core_private_ips" "k8s-bastion-private-ip" {
  subnet_id = oci_core_subnet.k8s-bastion-subnet.id
  vnic_id   = data.oci_core_vnic_attachments.k8s-bastion-vnic-attachments.vnic_attachments.0.vnic_id
}

resource "oci_core_public_ip" "k8s-bastion-public-ip" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-bastion-public-ip"
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.k8s-bastion-private-ip.private_ips.0.id
}
