
variable "application" {
  type        = string
  description = "Name of the application"
  default     = "lifi-devops"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ami_id" {
  description = "Amazon Machine Image (AMI) ID for the EC2 instances"
  type        = string
  default     = "ami-0e86e20dae9224db8"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.medium"
}
