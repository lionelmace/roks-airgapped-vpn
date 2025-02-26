
##############################################################################
# Monitoring Services
##############################################################################


# Monitoring Variables
##############################################################################
variable "sysdig_plan" {
  description = "plan type"
  type        = string
  default     = "graduated-tier"
  # default     = "graduated-tier-sysdig-secure-plus-monitor"
}

variable "sysdig_service_endpoints" {
  description = "Only allow the value public-and-private. Previously it incorrectly allowed values of public and private however it is not possible to create public only or private only Cloud Monitoring instances."
  type        = string
  default     = "public-and-private"
}

variable "sysdig_private_endpoint" {
  description = "Add this option to connect to your Sysdig service instance through the private service endpoint"
  type        = bool
  default     = true
}

variable "sysdig_enable_platform_metrics" {
  type        = bool
  description = "Receive platform metrics in Sysdig"
  default     = false
}

variable "sysdig_use_vpe" {
  default = true
}

# Monitoring Resource
##############################################################################

module "cloud_monitoring" {
  source = "terraform-ibm-modules/observability-instances/ibm//modules/cloud_monitoring"
  # version = "latest" # Replace "latest" with a release version to lock into a specific release

  resource_group_id       = local.resource_group_id
  instance_name           = format("%s-%s", local.basename, "monitoring")
  plan                    = var.sysdig_plan
  service_endpoints       = var.sysdig_service_endpoints
  enable_platform_metrics = var.sysdig_enable_platform_metrics
  region                  = var.region
  tags                    = var.tags
  manager_key_tags        = var.tags
}

output "cloud_monitoring_crn" {
  description = "The CRN of the Cloud Monitoring instance"
  value       = module.cloud_monitoring.crn
}

# VPE (Virtual Private Endpoint) for Monitoring
##############################################################################
module "vpes" {
  source            = "terraform-ibm-modules/vpe-gateway/ibm"
  region            = var.region
  prefix            = "vpe"
  vpc_name          = ibm_is_vpc.vpc.name
  vpc_id            = ibm_is_vpc.vpc.id
  subnet_zone_list  = var.subnet_list
  resource_group_id = local.resource_group_id
  cloud_services = [
    {
      service_name = "sysdig-monitoring"
    }
  ]
}

## IAM
##############################################################################

resource "ibm_iam_access_group_policy" "iam-sysdig" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles           = ["Writer", "Editor"]

  resources {
    service           = "sysdig-monitor"
    resource_group_id = local.resource_group_id
  }
}
