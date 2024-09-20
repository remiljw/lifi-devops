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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic
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


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic
  }

  ingress {
    description = "HTTPS ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
resource "aws_lb_target_group" "lb_tg" {
  name     = "${var.application}-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
  health_check {
    path    = "/"
    matcher = "200-499"
    timeout = 15
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.lb_tg.arn
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
  key_name  = var.application
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
  target_group_arns   = [aws_lb_target_group.lb_tg.arn]
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
