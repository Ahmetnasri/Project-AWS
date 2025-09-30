##########################
# Create a security group
###########################

resource "aws_security_group" "ssh_access" {
  name   = "allow_ssh"
  vpc_id = "vpc-093f63f55e5487353" # Replace with your VPC ID

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere (use cautiously)
  }
}

##########################
# Generate a key pair
###########################


resource "tls_private_key" "scaling_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "deployer" {
  key_name   = "scaling-key"
  public_key = tls_private_key.scaling_key.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  filename = "${path.module}/ec2-key.pem"
  content  = tls_private_key.scaling_key.private_key_pem
  file_permission = "0400"
}


##########################
# Launch Template
###########################


resource "aws_launch_template" "this" {
  name_prefix   = "test-scaling-temp"
  image_id      = "ami-05a2d2d0a1020fecd"
  instance_type = "t2.micro"
  key_name      = "scaling-key"


  network_interfaces {
    security_groups = [aws_security_group.ssh_access.id]
  }

  monitoring {
    enabled = true
  }

  update_default_version = true

  #user_data = base64encode(local.user_data)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "test-scaling-temp"
    }
  }
}


###########################
# Auto Scaling Group
###########################

resource "aws_autoscaling_group" "this" {
  name                      = "test-auto-scaling-group"
  vpc_zone_identifier       = ["subnet-0d1b68b1abc90a8f0"]
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 4
  health_check_type         = "EC2"
  health_check_grace_period = 90
  capacity_rebalance        = true

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # Spread across AZs & replace on update without downtime
  placement_group = null

  # Replace unhealthy instances faster
  default_cooldown = 60

  tag {
    key                 = "Name"
    value               = "test-auto-scaling-group"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

###########################
# Scaling Policies (CPU)
###########################

# Scale OUT when average CPU >= 60% for 2 consecutive periods
resource "aws_autoscaling_policy" "cpu_scale_out" {
  name                   = "test-auto-scaling-group-scale-out"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60
  }
}


###########################
# Helpful Outputs
###########################

output "asg_name" {
  value       = aws_autoscaling_group.this.name
  description = "Auto Scaling Group name"
}

output "security_group_id" {
  value       = aws_security_group.ssh_access.id
  description = "Security Group ID for the instances"
}

output "launch_template_id" {
  value       = aws_launch_template.this.id
  description = "Launch Template ID"
}
