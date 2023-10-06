provider "aws" {
  region = us-east-1
}

# Define a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# Define two availability zones
data "aws_availability_zones" "available" {}

# Define two public subnets in separate AZs for high availability
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.example.id
  cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

# Create a custom route table
resource "aws_route_table" "custom_route_table" {
  vpc_id = aws_vpc.example.id
}

# Define routes in the custom route table (exclude local route)
resource "aws_route" "route_to_internet" {
  route_table_id         = aws_route_table.custom_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.example.id
}

# Create an internet gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# Define an AWS IAM role for EC2 instances
resource "aws_iam_instance_profile" "example" {
  name = "example-profile"
}

resource "aws_iam_role" "example" {
  name = "example-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess" # Example policy
  role       = aws_iam_role.example.name
}

# Create an Auto Scaling Group
resource "aws_launch_template" "example" {
  name_prefix   = "example-lt-"
  instance_type = "t2.micro"
  
  iam_instance_profile {
    name = aws_iam_instance_profile.example.name
  }
}

resource "aws_autoscaling_group" "example" {
  name                      = "example-asg"
  vpc_zone_identifier       = aws_subnet.public_subnet[*].id
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  
  min_size             = 2
  max_size             = 2
  desired_capacity     = 2
  health_check_type    = "EC2"
  default_cooldown     = 300
  availability_zones   = data.aws_availability_zones.available.names[0:2]
  termination_policies = ["Default"]
  wait_for_capacity_timeout = "10m"
}

# Create an Application Load Balancer (ALB)
resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  enable_deletion_protection = false
  enable_http2       = true
  
  subnet_mapping {
    subnet_id     = aws_subnet.public_subnet[0].id
    allocation_id = aws_subnet.public_subnet[0].id
  }
  
  subnet_mapping {
    subnet_id     = aws_subnet.public_subnet[1].id
    allocation_id = aws_subnet.public_subnet[1].id
  }
}

# Create target group
resource "aws_lb_target_group" "example" {
  name        = "example-target-group"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.example.id
}

# Attach instances to the target group
resource "aws_lb_target_group_attachment" "example" {
  target_group_arn = aws_lb_target_group.example.arn
  target_id        = aws_autoscaling_group.example.name
}
