output "aws_region" {
  description = "The AWS region in use"
  value       = var.region
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id  
}

output "alb_sg_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "app_sg_id" {
  description = "The ID of the application security group"
  value       = aws_security_group.app_sg.id
}

output "app_alb_dns_name" {
  description = "The DNS name of the application load balancer"
  value       = aws_lb.app_alb.dns_name
}

output "app_tg_arn" {
  description = "The ARN of the application target group"
  value       = aws_lb_target_group.app_tg.arn
}

output "app_listener_arn" {
  description = "The ARN of the application load balancer listener"
  value       = aws_lb_listener.app_listener.arn
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.bucket_for_website.bucket
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.app_lt_custom.id
}

output "autoscaling_group_name" {
  description = "The name of the auto scaling group"
  value       = aws_autoscaling_group.app_asg_custom.name
}

output "s3_full_access_policy_arn" {
  description = "The ARN of the S3 full access policy"
  value       = aws_iam_policy.s3_full_access_policy.arn
}

output "iam_user_name" {
  description = "The name of the IAM user"
  value       = data.aws_iam_user.user.user_name
}

output "s3_bucket_policy_id" {
  description = "The ID of the S3 bucket policy"
  value       = aws_s3_bucket_policy.public_read_policy.id
}


output "alb_sg_ingress_rules" {
  description = "Ingress rules for the ALB security group"
  value = aws_security_group.alb_sg.ingress
}

output "alb_sg_egress_rules" {
  description = "Egress rules for the ALB security group"
  value = aws_security_group.alb_sg.egress
}

output "app_sg_ingress_rules_from_http_port" {
  description = "Ingress rules for the application security group"
  value = tolist(aws_security_group.app_sg.ingress)[0].from_port
}

output "app_sg_ingress_rules_to_http_port" {
  description = "Ingress rules for the application security group"
  value = tolist(aws_security_group.app_sg.ingress)[0].to_port
}


output "alb_sg_ingress_rules_from_http_port" {
  description = "Ingress rules for the ALB security group"
  value = tolist(aws_security_group.alb_sg.ingress)[0].from_port
}

output "alb_sg_ingress_rules_to_http_port" {
  description = "Ingress rules for the ALB security group"
  value = tolist(aws_security_group.alb_sg.ingress)[0].to_port
}



