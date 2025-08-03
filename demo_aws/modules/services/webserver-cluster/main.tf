provider "aws" {
region = "ap-southeast-1"
}

locals {
  http_port = 80 
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips= ["0.0.0.0/0"]
}

resource "aws_launch_template" "example" {
  image_id = "ami-02c7683e4ca3ebf58" # Ubuntu 22.04 LTS for ap-southeast-1
  instance_type = var.instance_type
  //subnet_id = aws_subnet.sbn_instance.id
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port   # Use the variable defined in variables.tf
  }))

  network_interfaces {
    security_groups = [aws_security_group.sg_instance.id]
  }
    
    # Required when using a launch configuration with an auto scaling group.
    lifecycle {
    create_before_destroy = true
    }
}     

resource "aws_autoscaling_group" "autoscalegrp_instance" {
  //launch_configuration = aws_launch_configuration.example.id
  min_size = var.min_size
  max_size = var.max_size
  vpc_zone_identifier = [aws_subnet.sbn_instance.id, aws_subnet.sbn_instance_2.id]
  target_group_arns = [aws_lb_target_group.aws_lb_target_group_instance.arn]
  health_check_type = "EC2"
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "demo-aws-instance"
    propagate_at_launch = true
  }
  
}

resource "aws_vpc" "vp_instance" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "sbn_instance" {
  vpc_id            = aws_vpc.vp_instance.id
  cidr_block        = "10.0.0.0/24"
  availability_zone       = "ap-southeast-1a" # Specify the availability zone
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sbn_instance_2" {
  vpc_id                  = aws_vpc.vp_instance.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1b" # Use a different AZ than your first subnet
  map_public_ip_on_launch = true
}

resource "aws_security_group" "sg_instance" {
  name        = "${var.cluster_name}-sg-instance"
  description = "Security group for demo AWS instance"
    vpc_id      = aws_vpc.vp_instance.id
}

resource "aws_security_group_rule" "allow_http_E2instance_inbound" {
  type        = "ingress"
  from_port   = var.server_port
  to_port     = var.server_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
  security_group_id = aws_security_group.sg_instance.id
  
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

data "aws_vpc" "custom_data_vpc" {
    id = aws_vpc.vp_instance.id
}

#load balancer
resource "aws_lb" "lb_instance" {
  name               = "${var.cluster_name}-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.sbn_instance.id, aws_subnet.sbn_instance_2.id]
  security_groups    = [aws_security_group.sg_lb_instance.id] 
}

#load balancer listener
resource "aws_lb_listener" "listener_instance" {
  load_balancer_arn = aws_lb.lb_instance.arn
  port              = local.http_port
  protocol          = "HTTP"
  
  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "sg_lb_instance" {
  name        = "${var.cluster_name}-lb-sg"
  description = "Security group for demo AWS load balancer"
  vpc_id      = aws_vpc.vp_instance.id

}

resource "aws_security_group_rule" "allow_http_inbound" {
  type        = "ingress"
  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
  security_group_id = aws_security_group.sg_lb_instance.id
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
  security_group_id = aws_security_group.sg_lb_instance.id
  
}

resource "aws_lb_target_group" "aws_lb_target_group_instance" {
  name     = "${var.cluster_name}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.custom_data_vpc.id

  health_check {
    path                = "/"
    protocol = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
}

resource "aws_lb_listener_rule" "ags" {
  listener_arn = aws_lb_listener.listener_instance.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.aws_lb_target_group_instance.arn
  }

  condition {
    path_pattern {
        values = ["*"]
    }
  }
}







