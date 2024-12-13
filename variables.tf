variable "openshift_version" {
  type    = string
  default = "4.17.9"
}

variable "cluster_name" {
  type = string
}

variable "aws_billing_account_id" {
  type    = string
  default = null
}

variable "version_channel_group" {
  type    = string
  default = "stable"
}

variable "restrict_shared_vpc_roles" {
  type    = bool
  default = "false"
}

variable "network_owner_aws_access_key_id" {
  type        = string
  default     = ""
  description = "The access key provides access to AWS services and is associated with the shared-vpc AWS account."
}

variable "network_owner_aws_secret_access_key" {
  type        = string
  default     = ""
  description = "The secret key paired with the access key. Together, they provide the necessary credentials for Terraform to authenticate with the shared-vpc AWS account and manage resources securely."
  sensitive   = true
}

variable "network_owner_aws_profile" {
  type        = string
  default     = ""
  description = "The name of the AWS profile configured in the AWS credentials file (typically located at ~/.aws/credentials). This profile contains the access key, secret key, and optional session token associated with the shared-vpc AWS account."
}

variable "network_owner_aws_shared_credentials_files" {
  type        = list(string)
  default     = null
  description = "List of files path to the AWS shared credentials file. This file typically contains AWS access keys and secret keys and is used when authenticating with AWS using profiles (default file located at ~/.aws/credentials)."
}

variable "cluster_owner_aws_access_key_id" {
  type        = string
  default     = ""
  description = "The access key provides access to AWS services and is associated with the shared-vpc AWS account."
}

variable "cluster_owner_aws_secret_access_key" {
  type        = string
  default     = ""
  description = "The secret key paired with the access key. Together, they provide the necessary credentials for Terraform to authenticate with the shared-vpc AWS account and manage resources securely."
  sensitive   = true
}

variable "cluster_owner_aws_profile" {
  type        = string
  default     = ""
  description = "The name of the AWS profile configured in the AWS credentials file (typically located at ~/.aws/credentials). This profile contains the access key, secret key, and optional session token associated with the shared-vpc AWS account."
}

variable "cluster_owner_aws_shared_credentials_files" {
  type        = list(string)
  default     = null
  description = "List of files path to the AWS shared credentials file. This file typically contains AWS access keys and secret keys and is used when authenticating with AWS using profiles (default file located at ~/.aws/credentials)."
}
