resource "oci_identity_dynamic_group" "bastion-dynamic-group" {
  compartment_id = var.compartment_ocid
  description    = "Dynamic group for the bastion host"
  name           = "bastion-dynamic-group"
  matching_rule  = "ALL {instance.id = '${oci_core_instance.k8s-bastion.id}'}"
}

resource "oci_identity_policy" "bastion-k8s-access" {
  compartment_id = var.compartment_ocid
  description    = "Policy to allow access bastion host to the Kubernetes"
  name           = "bastion-k8s-access"
  statements = [
    "Allow dynamic-group id ${oci_identity_dynamic_group.bastion-dynamic-group.id} to manage cluster-family in tenancy",
  ]
}
