resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh-key.private_key_pem
  filename = var.ssh_key_export_path
}
