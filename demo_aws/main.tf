provider "aws" {
region = "ap-southeast-1"
}

resource "aws_instance" "example" {
  ami = "ami-02c7683e4ca3ebf58" # Example AMI ID, replace with a valid one
  instance_type = "t3.micro"
    tags = {
        Name = "demo-aws-instance"
    }   
}   