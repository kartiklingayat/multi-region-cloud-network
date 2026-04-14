variable "region_name" {}
variable "environment" {}
variable "vpc_cidr" {}
variable "instance_type" {}
variable "key_name" { default = "" }
variable "alb_priority" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
