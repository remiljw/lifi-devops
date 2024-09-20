locals {
  lb_config = {
    http = {
      port     = 80
      protocol = "TCP"
    }
    https = {
      port     = 443
      protocol = "TCP"
    }
  }
}

# VPC creation
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "${var.application}-vpc"
  cidr   = var.vpc_cidr
  azs    = var.availability_zones

  public_subnets = var.public_subnets

  enable_nat_gateway   = false
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Security Group for EC2 instances (allowing SSH and Kubernetes traffic)
resource "aws_security_group" "ec2_sg" {
  name   = "${var.application}-ec2-sg"
  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.ec2_security_group_ingresses

    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", [aws_security_group.nlb_sg.id])
      description     = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load Balancer Security Group
resource "aws_security_group" "nlb_sg" {
  name   = "${var.application}-nlb-sg"
  vpc_id = module.vpc.vpc_id


  dynamic "ingress" {
    for_each = var.lb_security_group_ingresses

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
      description = ingress.value.description
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Load Balancer
resource "aws_lb" "nlb" {
  name               = "${var.application}-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_sg.id]
  subnets            = module.vpc.public_subnets
}

# Load Balancer Target Group
resource "aws_lb_target_group" "tg" {
  for_each = local.lb_config

  name     = "${var.application}-${each.key}-tg"
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = module.vpc.vpc_id

  health_check {
    path    = "/"
    matcher = "200-499"
    timeout = 15
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "listener" {
  for_each = local.lb_config

  load_balancer_arn = aws_lb.nlb.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }
}

#Auto scaling group attachment 
resource "aws_autoscaling_attachment" "asg_attachment" {
  for_each = aws_lb_target_group.tg

  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = each.value.arn
}

# Launch Template for Auto Scaling Group
resource "aws_launch_template" "asg_lt" {
  name          = "${var.application}-lc"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = filebase64("${path.module}/setup.sh")
  monitoring {
    enabled = true
  }


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.application}-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for EC2 instances
resource "aws_autoscaling_group" "asg" {
  name                = "${var.application}-asg"
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = module.vpc.public_subnets
  target_group_arns   = values(aws_lb_target_group.tg)[*].arn
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }
}


resource "aws_autoscaling_policy" "asg_policy" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name                   = "${var.application}-asg-policy"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
