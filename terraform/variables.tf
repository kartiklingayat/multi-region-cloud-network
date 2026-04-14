variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region"
  type        = string
  default     = "us-west-2"
}

variable "domain_name" {
  description = "Route53 domain name (must be a hosted zone)"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH (optional)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "failover-lab"
}
