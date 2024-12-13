# Reference Private ROSA HCP shared vpc
This terraform management file will generate a reference Private ROSA HCP cluster in shared vpc architecture.
Includes:
* Cluster owner account
  * Account roles
  * OIDC Config and Provider
  * Operator roles
  * Cluster
  * Shared VPC Assume Roles
    * Route53 assume role
    * Attached to
      * Installer Account Role
      * Ingress Operator Role
      * Control Plane Operator Role
  * VPCE assume role
    * Attached to
      * Installer Account Role
      * Control Plane Operator Role
* Network owner account
  * VPC
    * 1 Private Subnet
    * 1 Public Subnet
  * Hosted Zones
    * Ingress Private Hosted Zone
    * HCP Internal Communication Hosted Zone
  * Shared VPC Roles
    * Route53 role
    * VPCE role
  * Shared Resources
    * Shares Private Subnet to Cluster owner account
  * Bastion Host tied to the public subnet with ingress configuration to allow IP of the current machine

It depends on customer opening a support request to enable the feature for their organization, otherwise will meet error regarding feature not available for hcp clusters.
Also depends on utilizing [customer managed policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-vs-inline.html) for shared vpc roles and modules pointing to a feature branch of [terraform-rhcs-rosa-hcp](https://github.com/terraform-redhat/terraform-rhcs-rosa-hcp/tree/shared-vpc)

# Usage

## Planning

- Full usage with command line variable

        $ terraform plan -out rosa.tfplan \
            -var cluster_name=rosa-hcp \
            -var openshift_version=4.17.9 \
            -var cluster_owner_aws_profile=cluster_owner_aws_profile \
            -var network_owner_aws_profile=network_owner_aws_profile

## Apply

    $ terraform apply rosa.tfplan

## Post cluster ready

    Once apply is finished successfully the scripts within the /assets folder may be used to access the private cluster via `oc` CLI
    ```
    sh ./assets/bastion_connect.sh
    ```
    Generates a transparent proxy via sshuttle that forwards ssh to the bastion host
    Logins in to the cluster via oc
    ```
    oc get co
    ```
    Sample command to test cluster connection, will describe cluster operators resources
    ```
    sh ./assets/bastion_disconnect.sh
    ```
    Kills the sshuttle daemon based on the pid stored in local file
# Reference

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.38.0 |
| null | >= 3.0.0 |
| random | >= 3.6.3 |
| rhcs | = 1.6.8-prerelease.1 |

## Providers

| Name | Version |
|------|---------|
| aws | 5.81.0 |
| aws.cluster-owner | 5.81.0 |
| aws.network-owner | 5.81.0 |
| random | 3.6.3 |
| rhcs | 1.6.8-prerelease.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| account\_iam\_resources | github.com/terraform-redhat/terraform-rhcs-rosa-hcp//modules/account-iam-resources | shared-vpc |
| bastion\_host | github.com/terraform-redhat/terraform-rhcs-rosa-hcp/modules/bastion-host | n/a |
| oidc\_config\_and\_provider | terraform-redhat/rosa-hcp/rhcs//modules/oidc-config-and-provider | 1.6.5 |
| operator\_roles | github.com/terraform-redhat/terraform-rhcs-rosa-hcp//modules/operator-roles | shared-vpc |
| rosa\_cluster\_hcp | github.com/terraform-redhat/terraform-rhcs-rosa-hcp//modules/rosa-cluster-hcp | shared-vpc |
| shared-vpc-resources | github.com/terraform-redhat/terraform-rhcs-rosa-hcp//modules/shared-vpc-resources | shared-vpc |
| vpc | terraform-redhat/rosa-hcp/rhcs//modules/vpc | 1.6.5 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_tag.tag_private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [rhcs_dns_domain.dns_domain](https://registry.terraform.io/providers/terraform-redhat/rhcs/1.6.8-prerelease.1/docs/resources/dns_domain) | resource |
| [aws_ami.rhel9](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.cluster-owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.network-owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.network-owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.cluster-owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_region.network-owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws\_billing\_account\_id | n/a | `string` | `null` | no |
| cluster\_name | n/a | `string` | n/a | yes |
| cluster\_owner\_aws\_access\_key\_id | The access key provides access to AWS services and is associated with the shared-vpc AWS account. | `string` | `""` | no |
| cluster\_owner\_aws\_profile | The name of the AWS profile configured in the AWS credentials file (typically located at ~/.aws/credentials). This profile contains the access key, secret key, and optional session token associated with the shared-vpc AWS account. | `string` | `""` | no |
| cluster\_owner\_aws\_secret\_access\_key | The secret key paired with the access key. Together, they provide the necessary credentials for Terraform to authenticate with the shared-vpc AWS account and manage resources securely. | `string` | `""` | no |
| cluster\_owner\_aws\_shared\_credentials\_files | List of files path to the AWS shared credentials file. This file typically contains AWS access keys and secret keys and is used when authenticating with AWS using profiles (default file located at ~/.aws/credentials). | `list(string)` | `null` | no |
| network\_owner\_aws\_access\_key\_id | The access key provides access to AWS services and is associated with the shared-vpc AWS account. | `string` | `""` | no |
| network\_owner\_aws\_profile | The name of the AWS profile configured in the AWS credentials file (typically located at ~/.aws/credentials). This profile contains the access key, secret key, and optional session token associated with the shared-vpc AWS account. | `string` | `""` | no |
| network\_owner\_aws\_secret\_access\_key | The secret key paired with the access key. Together, they provide the necessary credentials for Terraform to authenticate with the shared-vpc AWS account and manage resources securely. | `string` | `""` | no |
| network\_owner\_aws\_shared\_credentials\_files | List of files path to the AWS shared credentials file. This file typically contains AWS access keys and secret keys and is used when authenticating with AWS using profiles (default file located at ~/.aws/credentials). | `list(string)` | `null` | no |
| openshift\_version | n/a | `string` | `"4.17.9"` | no |
| restrict\_shared\_vpc\_roles | n/a | `bool` | `"false"` | no |
| version\_channel\_group | n/a | `string` | `"stable"` | no |

## Outputs

| Name | Description |
|------|-------------|
| account\_role\_prefix | The prefix used for all generated AWS resources. |
| account\_roles\_arn | A map of Amazon Resource Names (ARNs) associated with the AWS IAM roles created. The key in the map represents the name of an AWS IAM role, while the corresponding value represents the associated Amazon Resource Name (ARN) of that role. |
| bastion\_host\_public\_ip | Bastion Host Public IP |
| cluster\_admin\_password | The password of the admin user. |
| cluster\_admin\_username | The username of the admin user. |
| cluster\_api\_url | URL of the API server. |
| cluster\_id | Unique identifier of the cluster. |
| console\_url | URL of the console. |
| current\_version | The currently running version of OpenShift on the cluster, for example '4.11.0'. |
| domain | DNS domain of cluster. |
| oidc\_config\_id | The unique identifier associated with users authenticated through OpenID Connect (OIDC) generated by this OIDC config. |
| oidc\_endpoint\_url | Registered OIDC configuration issuer URL, generated by this OIDC config. |
| operator\_role\_prefix | Prefix used for generated AWS operator policies. |
| operator\_roles\_arn | List of Amazon Resource Names (ARNs) for all operator roles created. |
| password | n/a |
| path | The arn path for the account/operator roles as well as their policies. |
| state | The state of the cluster. |