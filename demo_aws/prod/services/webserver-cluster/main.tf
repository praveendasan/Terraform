provider "aws" {
region = "ap-southeast-1"
}

module "module_webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  #assignment of variables
  cluster_name = "webservers-prod"
  db_remote_state_bucket = "(Your S3 bucket name)"
  db_remote_state_key = "path/to/your/remote/state/file"
  server_port = 8080
  min_size = 2
  max_size = 2
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  autoscaling_group_name = module.module_webserver_cluster.asg_name
  min_size               = 2
  max_size               = 10
  desired_capacity       = 10
  recurrence             = "0 9 * * *" # Scale out at 9 AM on weekdays
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  autoscaling_group_name = module.module_webserver_cluster.asg_name
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *" # Scale in at 5 PM on weekdays
}

