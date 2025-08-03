variable "cluster_name" {
  description = "The name to use for all all cluster resources"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for remote state storage"
  type        = string
}
variable "db_remote_state_key" {
  description = "The key for the remote state file in the S3 bucket"
  type        = string
}
variable "server_port" {
  description = "The port on which the server will run"
  type        = number
  default     = 8080
}

variable "instance_type" {
  description = "The type of the instance"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling group"
  type        = number
  default     = 10
}