provider "aws" {
  region = "us-east-1"
  alias  = "rds"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/live-acf-ocio-database-engineer"
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "infra"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/live-acf-ocio-infrastructure-engineer"
  }
}