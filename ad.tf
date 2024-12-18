data "oci_identity_availability_domains" "regional_ads" {
  compartment_id = var.compartment_ocid
}
