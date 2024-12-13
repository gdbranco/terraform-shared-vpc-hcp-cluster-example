############################
# Data blocks
############################
data "aws_region" "current" {}
provider "aws" {
  alias = "cluster-owner"

  access_key               = var.cluster_owner_aws_access_key_id
  secret_key               = var.cluster_owner_aws_secret_access_key
  region                   = data.aws_region.current.name
  profile                  = var.cluster_owner_aws_profile
  shared_credentials_files = var.cluster_owner_aws_shared_credentials_files
}
data "aws_region" "cluster-owner" {
  provider = aws.cluster-owner
}
data "aws_caller_identity" "cluster-owner" {
  provider = aws.cluster-owner
}
provider "aws" {
  alias = "network-owner"

  access_key               = var.network_owner_aws_access_key_id
  secret_key               = var.network_owner_aws_secret_access_key
  region                   = data.aws_region.current.name
  profile                  = var.network_owner_aws_profile
  shared_credentials_files = var.network_owner_aws_shared_credentials_files
}
data "aws_partition" "network-owner" {
  provider = aws.network-owner
}
data "aws_region" "network-owner" {
  provider = aws.network-owner
}
data "aws_caller_identity" "network-owner" {
  provider = aws.network-owner
}

############################
# Locals
############################
locals {
  account_role_prefix          = "${var.cluster_name}-acc"
  operator_role_prefix         = "${var.cluster_name}-op"
  shared_resources_name_prefix = var.cluster_name
  shared_route53_role_name     = substr("${local.shared_resources_name_prefix}-shared-route53-role", 0, 64)
  shared_vpce_role_name        = substr("${local.shared_resources_name_prefix}-shared-vpce-role", 0, 64)
  # Required to generate the expected names for the shared vpc role arns
  # There is a cyclic dependency on the shared vpc role arns and the installer,control-plane,ingress roles
  # that is because AWS will not accept to include these into the trust policy without first creating it
  # however, will allow to generate a permission policy with these values before the creation of the roles
  shared_vpc_roles_arns = {
    "route53" : "arn:${data.aws_partition.network-owner.partition}:iam::${data.aws_caller_identity.network-owner.account_id}:role/${local.shared_route53_role_name}",
    "vpce" : "arn:${data.aws_partition.network-owner.partition}:iam::${data.aws_caller_identity.network-owner.account_id}:role/${local.shared_vpce_role_name}"
  }
}
############################
# Account Roles
############################
module "account_iam_resources" {
  providers = {
    aws = aws.cluster-owner
  }
  source                     = "github.com/terraform-redhat/terraform-rhcs-rosa-hcp//modules/account-iam-resources?ref=shared-vpc"
  account_role_prefix        = local.account_role_prefix
  create_shared_vpc_policies = true
  shared_vpc_roles           = local.shared_vpc_roles_arns
}

############################
# Oidc Config
############################
module "oidc_config_and_provider" {
  providers = {
    aws = aws.cluster-owner
  }
  source  = "terraform-redhat/rosa-hcp/rhcs//modules/oidc-config-and-provider"
  version = "1.6.5"
}

############################
# Operator Roles
############################
module "operator_roles" {
  providers = {
    aws = aws.cluster-owner
  }
  source               = "github.com/terraform-redhat/terraform-rhcs-rosa-hcp//modules/operator-roles?ref=shared-vpc"
  oidc_endpoint_url    = module.oidc_config_and_provider.oidc_endpoint_url
  operator_role_prefix = local.operator_role_prefix
  # Already created the policies on account iam resources module
  create_shared_vpc_policies = false
  shared_vpc_roles           = local.shared_vpc_roles_arns
}

############################
# shared-vpc-resources
############################
module "shared-vpc-resources" {
  source = "github.com/terraform-redhat/terraform-rhcs-rosa-hcp//modules/shared-vpc-resources?ref=shared-vpc"

  providers = {
    aws = aws.network-owner
  }

  cluster_name                            = var.cluster_name
  account_roles_prefix                    = module.account_iam_resources.account_role_prefix
  operator_roles_prefix                   = module.operator_roles.operator_role_prefix
  ingress_private_hosted_zone_base_domain = rhcs_dns_domain.dns_domain.id
  name_prefix                             = local.shared_resources_name_prefix
  target_aws_account                      = data.aws_caller_identity.cluster-owner.account_id
  subnets                                 = concat(module.vpc.private_subnets)
  vpc_id                                  = module.vpc.vpc_id
}

resource "aws_ec2_tag" "tag_private_subnets" {
  provider    = aws.cluster-owner
  count       = length(module.vpc.private_subnets)
  resource_id = module.vpc.private_subnets[count.index]
  key         = "kubernetes.io/role/internal-elb"
  value       = ""
}

###
# Further restrict shared vpc roles if needed
###
resource "aws_iam_policy" "restrict_route53_policy" {
  count    = var.restrict_shared_vpc_roles ? 1 : 0
  provider = aws.network-owner
  name     = "${module.shared-vpc-resources.route53_role_name}-restrict-policy"
  policy = templatefile(
    "./assets/restrict-route53-policy.tpl",
    {
      ingress_hosted_zone_arn                    = module.shared-vpc-resources.ingress_private_hosted_zone_arn,
      hcp_internal_communication_hosted_zone_arn = module.shared-vpc-resources.hcp_internal_communication_private_hosted_zone_arn,
    },
  )
}

resource "aws_iam_role_policy_attachment" "route53_role_restriction_attachment" {
  count      = var.restrict_shared_vpc_roles ? 1 : 0
  provider   = aws.network-owner
  role       = module.shared-vpc-resources.route53_role_name
  policy_arn = aws_iam_policy.restrict_route53_policy[count.index].arn
}

resource "aws_iam_policy" "restrict_vpce_policy" {
  count    = var.restrict_shared_vpc_roles ? 1 : 0
  provider = aws.network-owner
  name     = "${module.shared-vpc-resources.vpce_role_name}-restrict-policy"
  policy = templatefile(
    "./assets/restrict-vpce-policy.tpl",
    {
      aws_vpc_id = module.vpc.vpc_id,
    },
  )
}

resource "aws_iam_role_policy_attachment" "vpce_role_restriction_attachment" {
  count      = var.restrict_shared_vpc_roles ? 1 : 0
  provider   = aws.network-owner
  role       = module.shared-vpc-resources.vpce_role_name
  policy_arn = aws_iam_policy.restrict_vpce_policy[count.index].arn
}

############
# Dns Reservation
############
resource "rhcs_dns_domain" "dns_domain" {
  cluster_arch = "hcp"
}
############
# VPC
############
module "vpc" {
  providers = {
    aws = aws.network-owner
  }
  source  = "terraform-redhat/rosa-hcp/rhcs//modules/vpc"
  version = "1.6.5"

  name_prefix              = var.cluster_name
  availability_zones_count = 1
}

############################
# ROSA STS cluster
############################
module "rosa_cluster_hcp" {
  source = "github.com/terraform-redhat/terraform-rhcs-rosa-hcp//modules/rosa-cluster-hcp?ref=shared-vpc"
  providers = {
    aws = aws.cluster-owner
  }

  cluster_name               = var.cluster_name
  openshift_version          = var.openshift_version
  version_channel_group      = var.version_channel_group
  machine_cidr               = module.vpc.cidr_block
  aws_subnet_ids             = module.shared-vpc-resources.shared_subnets
  replicas                   = 2
  private                    = true
  create_admin_user          = true
  admin_credentials_username = "admin"
  admin_credentials_password = random_password.password.result
  ec2_metadata_http_tokens   = "required"
  aws_billing_account_id     = var.aws_billing_account_id

  // STS configuration
  oidc_config_id       = module.oidc_config_and_provider.oidc_config_id
  account_role_prefix  = module.account_iam_resources.account_role_prefix
  operator_role_prefix = module.operator_roles.operator_role_prefix
  shared_vpc = {
    ingress_private_hosted_zone_id                = module.shared-vpc-resources.ingress_private_hosted_zone_id
    internal_communication_private_hosted_zone_id = module.shared-vpc-resources.hcp_internal_communication_private_hosted_zone_id
    route53_role_arn                              = module.shared-vpc-resources.route53_role_arn
    vpce_role_arn                                 = module.shared-vpc-resources.vpce_role_arn
  }
  base_dns_domain                   = rhcs_dns_domain.dns_domain.id
  aws_additional_allowed_principals = [module.shared-vpc-resources.route53_role_arn, module.shared-vpc-resources.vpce_role_arn]
  depends_on = [
    aws_iam_role_policy_attachment.route53_role_restriction_attachment,
    aws_iam_role_policy_attachment.vpce_role_restriction_attachment,
  ]
}

resource "random_password" "password" {
  length      = 14
  special     = true
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

############################
# Bastion instance for connection to the cluster
############################
module "bastion_host" {
  providers = {
    aws = aws.network-owner
  }
  # Not yet available in official release
  source     = "github.com/terraform-redhat/terraform-rhcs-rosa-hcp//modules/bastion-host?ref=shared-vpc"
  prefix     = var.cluster_name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.public_subnets[0]]
}
