resource "oci_core_vcn" "k8s-vcn" {
  cidr_blocks    = [var.vcn_cidr]
  compartment_id = var.compartment_ocid
  display_name   = "k8s-vcn"
  is_ipv6enabled = "false"
  dns_label      = "k8svcn"
}

resource "oci_core_internet_gateway" "k8s-igw" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-igw"
  vcn_id         = oci_core_vcn.k8s-vcn.id
}

resource "oci_core_nat_gateway" "k8s-nat" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-nat"
  vcn_id         = oci_core_vcn.k8s-vcn.id
}

data "oci_core_services" "oci-svc" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "k8s-sgw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s-vcn.id
  services {
    service_id = data.oci_core_services.oci-svc.services.0.id
  }
}

resource "oci_core_route_table" "k8s-pub-rt" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-pub-rt"
  vcn_id         = oci_core_vcn.k8s-vcn.id

  route_rules {
    network_entity_id = oci_core_internet_gateway.k8s-igw.id
    destination_type  = "CIDR_BLOCK"
    destination       = "0.0.0.0/0"
    description       = "Route to the Internet gateway"
  }
}

resource "oci_core_route_table" "k8s-priv-rt" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-priv-rt"
  vcn_id         = oci_core_vcn.k8s-vcn.id

  route_rules {
    network_entity_id = oci_core_service_gateway.k8s-sgw.id
    destination_type  = "SERVICE_CIDR_BLOCK"
    destination       = data.oci_core_services.oci-svc.services.0.cidr_block
    description       = "Route to the service gateway"
  }

  route_rules {
    network_entity_id = oci_core_nat_gateway.k8s-nat.id
    destination_type  = "CIDR_BLOCK"
    destination       = "0.0.0.0/0"
    description       = "Route to the NAT gateway"
  }
}

resource "oci_core_security_list" "k8s-endpoint-sl" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-endpoint-sl"
  vcn_id         = oci_core_vcn.k8s-vcn.id

  ingress_security_rules {
    source   = var.nodes_cidr
    protocol = 6
    tcp_options {
      max = 6443
      min = 6443
    }
    description = "Kubernetes worker to Kubernetes API endpoint communication"
  }

  ingress_security_rules {
    source   = var.nodes_cidr
    protocol = 6
    tcp_options {
      max = 12250
      min = 12250
    }
    description = "Kubernetes worker to Kubernetes API endpoint communication"
  }

  ingress_security_rules {
    source   = var.nodes_cidr
    protocol = 1
    icmp_options {
      type = 3
    }
    description = "Kubernetes worker to Kubernetes API Path Discovery"
  }

  ingress_security_rules {
    source   = var.nodes_cidr
    protocol = 1
    icmp_options {
      type = 4
    }
    description = "Kubernetes worker to Kubernetes API Path Discovery"
  }

  ingress_security_rules {
    source   = var.pods_cidr
    protocol = 6
    tcp_options {
      max = 6443
      min = 6443
    }
    description = "Pod to Kubernetes API endpoint communication"
  }

  ingress_security_rules {
    source   = var.pods_cidr
    protocol = 6
    tcp_options {
      max = 12250
      min = 12250
    }
    description = "Pod to Kubernetes API endpoint communication"
  }

  ingress_security_rules {
    source   = var.bastion_cidr
    protocol = 6
    tcp_options {
      max = 6443
      min = 6443
    }
    description = "Allow bastion to access the Kubernetes API endpoint"
  }

  egress_security_rules {
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.oci-svc.services.0.cidr_block
    protocol         = 6
    description      = "Allow Kubernetes API endpoint to communicate with OKE"
  }

  egress_security_rules {
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.oci-svc.services.0.cidr_block
    protocol         = 1
    icmp_options {
      type = 3
    }
    description = "Allow Kubernetes API endpoint to communicate with OKE"
  }

  egress_security_rules {
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.oci-svc.services.0.cidr_block
    protocol         = 1
    icmp_options {
      type = 4
    }
    description = "Allow Kubernetes API endpoint to communicate with OKE"
  }

  egress_security_rules {
    destination = var.nodes_cidr
    protocol    = 6
    tcp_options {
      max = 10250
      min = 10250
    }
    description = "Allow Kubernetes API endpoint to communicate with worker nodes"
  }

  egress_security_rules {
    destination = var.nodes_cidr
    protocol    = 1
    icmp_options {
      type = 3
    }
    description = "Allow Kubernetes API endpoint to communicate with worker nodes"
  }

  egress_security_rules {
    destination = var.nodes_cidr
    protocol    = 1
    icmp_options {
      type = 4
    }
    description = "Allow Kubernetes API endpoint to communicate with worker nodes"
  }

  egress_security_rules {
    destination = var.pods_cidr
    protocol    = "all"
    description = "Allow Kubernetes API endpoint to communicate with pods"
  }
}

resource "oci_core_security_list" "k8s-nodes-sl" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-nodes-sl"
  vcn_id         = oci_core_vcn.k8s-vcn.id

  ingress_security_rules {
    source   = var.endpoint_cidr
    protocol = 6
    tcp_options {
      min = 10250
      max = 10250
    }
    description = "Allow Kubernetes API endpoint to communicate with worker nodes"
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = 1
    icmp_options {
      type = 3
    }
    description = "Path Discovery"
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = 1
    icmp_options {
      type = 4
    }
    description = "Path Discovery"
  }

  ingress_security_rules {
    source   = var.bastion_cidr
    protocol = 6
    tcp_options {
      min = 22
      max = 22
    }
    description = "Allow inbound SSH traffic to managed nodes"
  }

  ingress_security_rules {
    source      = var.load_balancer_cidr
    protocol    = "all"
    description = "Load balancer to worker nodes node ports"
  }

  ingress_security_rules {
    source      = var.load_balancer_cidr
    protocol    = "all"
    description = "Allow load balancer to communicate with kube-proxy on worker nodes"
  }

  egress_security_rules {
    destination = var.pods_cidr
    protocol    = "all"
    description = "Allow worker nodes to access pods"
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 1
    icmp_options {
      type = 3
    }
    description = "Path Discovery"
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 1
    icmp_options {
      type = 4
    }
    description = "Path Discovery"
  }

  egress_security_rules {
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.oci-svc.services.0.cidr_block
    protocol         = 6
    description      = "Allow worker nodes to communicate with OKE"
  }

  egress_security_rules {
    destination = var.endpoint_cidr
    protocol    = 6
    tcp_options {
      min = 6443
      max = 6443
    }
    description = "Kubernetes worker to Kubernetes API endpoint communication"
  }

  egress_security_rules {
    destination = var.endpoint_cidr
    protocol    = 6
    tcp_options {
      min = 12250
      max = 12250
    }
    description = "Kubernetes worker to Kubernetes API endpoint communication"
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6
    tcp_options {
      min = 443
      max = 443
    }
    description = "Allow worker nodes to communicate with the Internet (HTTPS)"
  }
}

resource "oci_core_security_list" "k8s-pods-sl" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-pods-sl"
  vcn_id         = oci_core_vcn.k8s-vcn.id

  ingress_security_rules {
    source      = var.nodes_cidr
    protocol    = "all"
    description = "Allow worker nodes to access pods"
  }

  ingress_security_rules {
    source      = var.endpoint_cidr
    protocol    = "all"
    description = "Allow Kubernetes API endpoint to communicate with pods"
  }

  ingress_security_rules {
    source      = var.pods_cidr
    protocol    = "all"
    description = "Allow pods to communicate with other pods"
  }

  egress_security_rules {
    destination = var.pods_cidr
    protocol    = "all"
    description = "Allow pods to communicate with other pods"
  }

  egress_security_rules {
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.oci-svc.services.0.cidr_block
    protocol         = 1
    icmp_options {
      type = 3
    }
    description = "Path Discovery"
  }

  egress_security_rules {
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.oci-svc.services.0.cidr_block
    protocol         = 1
    icmp_options {
      type = 4
    }
    description = "Path Discovery"
  }

  egress_security_rules {
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.oci-svc.services.0.cidr_block
    protocol         = 6
    description      = "Allow pods to communicate with OCI services"
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6
    tcp_options {
      min = 80
      max = 80
    }
    description = "Allow pods to communicate with the Internet (HTTP)"
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6
    tcp_options {
      min = 443
      max = 443
    }
    description = "Allow pods to communicate with the Internet (HTTPS)"
  }

  egress_security_rules {
    destination = var.endpoint_cidr
    protocol    = 6
    tcp_options {
      min = 6443
      max = 6443
    }
    description = "Pod to Kubernetes API endpoint communication"
  }

  egress_security_rules {
    destination = var.endpoint_cidr
    protocol    = 6
    tcp_options {
      min = 12250
      max = 12250
    }
    description = "Pod to Kubernetes API endpoint communication"
  }
}

resource "oci_core_security_list" "k8s-load-balancer-sl" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-load-balancer-sl"
  vcn_id         = oci_core_vcn.k8s-vcn.id

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = 6
    tcp_options {
      min = 80
      max = 80
    }
    description = "Allow HTTP traffic to the load balancer"
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = 6
    tcp_options {
      min = 443
      max = 443
    }
    description = "Allow HTTPS traffic to the load balancer"
  }

  egress_security_rules {
    destination = var.pods_cidr
    protocol    = "all"
    description = "Load balancer to worker nodes node ports"
  }

  egress_security_rules {
    destination = var.nodes_cidr
    protocol    = "all"
    description = "Allow load balancer to communicate with kube-proxy on worker nodes"
  }
}

resource "oci_core_security_list" "k8s-bastion-sl" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-bastion-sl"
  vcn_id         = oci_core_vcn.k8s-vcn.id

  egress_security_rules {
    destination = var.endpoint_cidr
    protocol    = 6
    tcp_options {
      min = 6443
      max = 6443
    }
    description = "Allow bastion to access the Kubernetes API endpoint"
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6
    tcp_options {
      min = 443
      max = 443
    }
    description = "Allow bastion to communicate with the Internet (HTTPS)"
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = 6
    tcp_options {
      min = 80
      max = 80
    }
    description = "Allow bastion to communicate with the Internet (HTTP)"
  }

  egress_security_rules {
    destination = var.nodes_cidr
    protocol    = 6
    tcp_options {
      min = 22
      max = 22
    }
    description = "Allow SSH traffic to worker nodes"
  }

  egress_security_rules {
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.oci-svc.services.0.cidr_block
    protocol         = 6
    description      = "Allow bastion to communicate with OKE"
  }

  egress_security_rules {
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.oci-svc.services.0.cidr_block
    protocol         = 1
    icmp_options {
      type = 3
    }
    description = "Allow bastion to communicate with OKE"
  }

  egress_security_rules {
    destination_type = "SERVICE_CIDR_BLOCK"
    destination      = data.oci_core_services.oci-svc.services.0.cidr_block
    protocol         = 1
    icmp_options {
      type = 4
    }
    description = "Allow bastion to communicate with OKE"
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = 6
    tcp_options {
      min = 22
      max = 22
    }
    description = "Allow SSH traffic to the bastion"
  }
}

resource "oci_core_subnet" "k8s-endpoint-subnet" {
  cidr_block                = var.endpoint_cidr
  compartment_id            = var.compartment_ocid
  display_name              = "k8s-endpoint-subnet"
  vcn_id                    = oci_core_vcn.k8s-vcn.id
  route_table_id            = oci_core_route_table.k8s-priv-rt.id
  security_list_ids         = [oci_core_security_list.k8s-endpoint-sl.id]
  prohibit_internet_ingress = true
}

resource "oci_core_subnet" "k8s-nodes-subnet" {
  cidr_block                = var.nodes_cidr
  compartment_id            = var.compartment_ocid
  display_name              = "k8s-nodes-subnet"
  vcn_id                    = oci_core_vcn.k8s-vcn.id
  route_table_id            = oci_core_route_table.k8s-priv-rt.id
  security_list_ids         = [oci_core_security_list.k8s-nodes-sl.id]
  prohibit_internet_ingress = true
}

resource "oci_core_subnet" "k8s-pods-subnet" {
  cidr_block                = var.pods_cidr
  compartment_id            = var.compartment_ocid
  display_name              = "k8s-pods-subnet"
  vcn_id                    = oci_core_vcn.k8s-vcn.id
  route_table_id            = oci_core_route_table.k8s-priv-rt.id
  security_list_ids         = [oci_core_security_list.k8s-pods-sl.id]
  prohibit_internet_ingress = true
}

resource "oci_core_subnet" "k8s-load-balancer-subnet" {
  cidr_block        = var.load_balancer_cidr
  compartment_id    = var.compartment_ocid
  display_name      = "k8s-load-balancer-subnet"
  vcn_id            = oci_core_vcn.k8s-vcn.id
  route_table_id    = oci_core_route_table.k8s-pub-rt.id
  security_list_ids = [oci_core_security_list.k8s-load-balancer-sl.id]
}

resource "oci_core_subnet" "k8s-bastion-subnet" {
  cidr_block        = var.bastion_cidr
  compartment_id    = var.compartment_ocid
  display_name      = "k8s-bastion-subnet"
  vcn_id            = oci_core_vcn.k8s-vcn.id
  route_table_id    = oci_core_route_table.k8s-pub-rt.id
  security_list_ids = [oci_core_security_list.k8s-bastion-sl.id]
}
