variable "account_id" {
  type        = string
  description = "The AWS Account ID"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "acf_vpn_ips" {
  type        = list(string)
  description = "IP address for ACF VPN"
}

variable "rds_security_groups" {
  type        = list(string)
  description = "Security groups for PIR database RDS"
}

variable "rds_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for PIR database"
}

variable "pir_vpc" {
  type        = string
  description = "VPC ID for PIR resources"
}

# variable "pir_vpc_route_table_ids" {
#   type = list(string)
#   description = "VPC Route IDs for PIR resources"
# }

variable "app_name" {
  type    = string
  default = "pir-qa-dashboard"
}

variable "pir_rds_arn" {
  type        = string
  description = "ARN for PIR database RDS"
}

variable "pir_s3_arn" {
  type        = string
  description = "ARN for PIR s3 bucket"
}

variable "pir_s3_name" {
  type    = string
  default = "pir-data-files"
}
