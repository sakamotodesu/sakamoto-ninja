terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = "= 0.13.5"
}

provider "aws" {
  version = "= 2.52.0"
  // ACMがus-east-1 にないとCloudFrontのカスタムドメインに設定できない。
  region = "us-east-1"
}