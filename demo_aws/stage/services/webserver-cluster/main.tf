provider "aws" {
region = "ap-southeast-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
}

