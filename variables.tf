variable "tenancy_ocid" {
  description = "The OCID of the tenancy."
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user."
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the public key used for authentication."
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key used for authentication."
  default     = "identity/oci-key.pem"
  type        = string
}

variable "region" {
  description = "The region to create resources."
  type        = string
  default     = "ap-chuncheon-1"
}

variable "compartment_ocid" {
  description = "The OCID of the compartment."
  type        = string
}

variable "ssh_key_export_path" {
  description = "The path to export the SSH key."
  type        = string
  default     = "outputs/ssh-key.pem"
}

variable "vcn_cidr" {
  description = "The CIDR block for the VCN."
  type        = string
  default     = "10.0.0.0/16"
}

variable "endpoint_cidr" {
  description = "The CIDR block for the Kubernetes API endpoint."
  type        = string
  default     = "10.0.1.0/24"
}

variable "nodes_cidr" {
  description = "The CIDR block for the worker nodes."
  type        = string
  default     = "10.0.2.0/24"
}

variable "load_balancer_cidr" {
  description = "The CIDR block for the load balancer."
  type        = string
  default     = "10.0.3.0/24"
}

variable "bastion_cidr" {
  description = "The CIDR block for the bastion host."
  type        = string
  default     = "10.0.4.0/24"
}

variable "pods_cidr" {
  description = "The CIDR block for the worker nodes."
  type        = string
  default     = "10.0.128.0/17"
}

variable "kubernetes_version" {
  description = "The version of Kubernetes."
  type        = string
  default     = "1.31.1"
}

variable "oracle_linux_version" {
  description = "The version of Oracle Linux."
  type        = string
  default     = "8.10"
}
