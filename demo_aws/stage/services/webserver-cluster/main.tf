provider "aws" {
region = "ap-southeast-1"
}

module "module_webserver_cluster" {
  #source = "../../../modules/services/webserver-cluster"
  source = "git@github.com:praveendasan/Terraform.git//demo_aws/modules/services/webserver-cluster?ref=v1.0.0"

  #assignment of variables
  cluster_name = "webservers-stage"
  db_remote_state_bucket = "(Your S3 bucket name)"
  db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
  server_port = 8080
  min_size = 2
  max_size = 2
}

resource "aws_security_group_rule" "allow_testing_inbound" {
  type        = "ingress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.module_webserver_cluster.aws_security_group_id
}

