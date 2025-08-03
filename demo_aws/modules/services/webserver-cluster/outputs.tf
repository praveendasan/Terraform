output "alb_dns_name" {
  value = aws_lb.lb_instance.dns_name   
  description = "The name of the Auto Scaling group"
}

output "asg_name" {
  value = aws_autoscaling_group.autoscalegrp_instance.name  
  description = "The name of the Auto Scaling group"
}

output "aws_security_group_id" {
  value = aws_security_group.sg_lb_instance.id
  description = "The ID of the security group for the load balancer"
  
}