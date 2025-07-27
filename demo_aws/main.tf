provider "aws" {
region = "ap-southeast-1"
}

resource "aws_instance" "example" {
  ami = "ami-02c7683e4ca3ebf58" # Ubuntu 22.04 LTS for ap-southeast-1
  instance_type = "t3.micro"
  subnet_id = aws_subnet.sbn_instance.id
  vpc_security_group_ids = [aws_security_group.sg_instance.id]

  user_data = <<-EOF
             #!/bin/bash
              yum update -y
              yum install -y busybox
              mkdir -p /www
              echo "<h1>Hello from BusyBox on port 8080!</h1>" > /www/index.html
              busybox httpd -f -p 8080 -h /www &
              EOF
              
    tags = {
        Name = "demo-aws-instance"
    }  

}   

resource "aws_vpc" "vp_instance" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "sbn_instance" {
  vpc_id            = aws_vpc.vp_instance.id
  cidr_block        = "10.0.0.0/24"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "sg_instance" {
  name        = "demo-aws-sg"
  description = "Security group for demo AWS instance"
    vpc_id      = aws_vpc.vp_instance.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "gw_instance" {
  vpc_id = aws_vpc.vp_instance.id
  
}
resource "aws_route_table" "rt_instance" {
  vpc_id = aws_vpc.vp_instance.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_instance.id
  }
}
resource "aws_route_table_association" "rta_instance" {
  subnet_id      = aws_subnet.sbn_instance.id
  route_table_id = aws_route_table.rt_instance.id
}
output "instance_public_ip" {
  value = aws_instance.example.public_ip
}