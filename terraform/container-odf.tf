# Install ODF (OpenShift Data Foundation)
##############################################################################
resource "ibm_container_addons" "addons" {
  cluster           = ibm_container_vpc_cluster.roks_cluster.id
  resource_group_id = local.resource_group_id
  addons {
    name            = "openshift-data-foundation"
    version         = "4.16.0"
    parameters_json = <<PARAMETERS_JSON
    {
        "osdSize":"200Gi",
        "numOfOsd":"1",
        "osdStorageClassName":"ibmc-vpc-block-metro-10iops-tier",
        "odfDeploy":"true"
    }
    PARAMETERS_JSON
  }
}