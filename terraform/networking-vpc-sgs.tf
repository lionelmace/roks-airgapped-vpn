# Security Groups
##############################################################################

# Rules required to allow necessary inbound traffic to your cluster (IKS/OCP)
##############################################################################
# To expose apps by using load balancers or Ingress, allow traffic through VPC 
# load balancers. For example, for Ingress listening on TCP/443
resource "ibm_is_security_group_rule" "sg-rule-inbound-icmp" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp {
    type = 8
  }
}

# Allow incoming ICMP packets (Ping)
##############################################################################
resource "ibm_is_security_group_rule" "sg-rule-inbound-https" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

# SSH Inbound Rule
##############################################################################
resource "ibm_is_security_group_rule" "sg-rule-inbound-ssh" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}


##############################################################################

resource "ibm_is_security_group" "kube-master-outbound" {
  name           = format("%s-%s", local.basename, "kube-master-outbound")
  vpc            = ibm_is_vpc.vpc.id
  resource_group = local.resource_group_id
}

resource "ibm_is_security_group_rule" "sg-rule-kube-master-tcp-outbound" {
  group     = ibm_is_security_group.kube-master-outbound.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 30000
    port_max = 32767
  }
}
resource "ibm_is_security_group_rule" "sg-rule-kube-master-udp-outbound" {
  group     = ibm_is_security_group.kube-master-outbound.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  udp {
    port_min = 30000
    port_max = 32767
  }
}

##############################################################################
# New Outbound security group rules to add for version 4.14 or later
# Source: https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-security-group&interface=ui#rules-sg-128
resource "ibm_is_security_group" "sg-cluster-outbound" {
  name           = format("%s-%s", local.basename, "kube-outbound-sg")
  vpc            = ibm_is_vpc.vpc.id
  resource_group = local.resource_group_id
}

resource "ibm_is_security_group_rule" "sg-rule-outbound-addprefix-443" {
  group     = ibm_is_security_group.sg-cluster-outbound.id
  count     = length(var.vpc_cidr_blocks)
  direction = "outbound"
  remote    = element(var.vpc_cidr_blocks, count.index)
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "sg-rule-outbound-addprefix-4443" {
  group     = ibm_is_security_group.sg-cluster-outbound.id
  count     = length(var.vpc_cidr_blocks)
  direction = "outbound"
  remote    = element(var.vpc_cidr_blocks, count.index)
  tcp {
    port_min = 4443
    port_max = 4443
  }
}
##############################################################################

# Allow access to the OpenShift Console my home IP address
# Required if allowing traffic only from CIS
##############################################################################
resource "ibm_is_security_group" "home-access" {
  name           = format("%s-%s", local.basename, "access-from-home")
  vpc            = ibm_is_vpc.vpc.id
  resource_group = local.resource_group_id
}

resource "ibm_is_security_group_rule" "sg-rule-inbound-home" {
  group     = ibm_is_security_group.home-access.id
  direction = "inbound"
  remote    = "90.8.141.48"
}