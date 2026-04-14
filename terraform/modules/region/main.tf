# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = { Name = "${var.environment}-${var.region_name}" }
}

# Public subnets (2 AZs)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "public-${count.index}" }
}

# Private subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "private-${count.index}" }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# NAT Gateways (one per public subnet)
resource "aws_eip" "nat" {
  count = 2
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Groups
resource "aws_security_group" "alb" {
  vpc_id = aws_vpc.this.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2" {
  vpc_id = aws_vpc.this.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template with user data (simple Flask app)
resource "aws_launch_template" "this" {
  name_prefix   = "${var.environment}-${var.region_name}"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.ec2.id]
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    region = var.region_name
  }))
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name               = "${var.environment}-${var.region_name}"
  vpc_zone_identifier = aws_subnet.private[*].id
  min_size           = 2
  max_size           = 4
  desired_capacity   = 2
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.region_name}"
    propagate_at_launch = true
  }
}

# Application Load Balancer
resource "aws_lb" "this" {
  name               = "${var.environment}-${var.region_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "this" {
  name        = "${var.environment}-${var.region_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.id
  lb_target_group_arn    = aws_lb_target_group.this.arn
}

# Outputs for the module
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}
output "alb_zone_id" {
  value = aws_lb.this.zone_id
}
output "alb_arn_suffix" {
  value = aws_lb.this.arn_suffix
}
