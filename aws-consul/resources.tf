##################################################################################
# CONFIGURATION - added for Terraform 0.14
##################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  profile = var.profile
  region  = var.region
}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>2.0"

  name = "infra-vpc"

  cidr            = var.cidr_block
  azs             = slice(data.aws_availability_zones.available.names, 0, var.subnet_count) // slice extracts some consecutive elements from within a list. slice(list, startindex, endindex)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_database_subnet_group = false


  tags = local.common_tags
}


# INSTANCES #
resource "aws_instance" "consul" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnets[0]

  vpc_security_group_ids = [
    aws_security_group.consul_http_inbound_sg.id,
    aws_security_group.consul_ssh_inbound_sg.id,
    aws_security_group.consul_sg.id,
  ]
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.consul_profile.name

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)

  }


  tags = merge(local.common_tags, { Name = "${local.common_tags.Environment}-consul" })

}

resource "aws_iam_role" "allow_consul_s3" {
  name = "${local.common_tags.Environment}_allow_consul_s3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "consul_profile" {
  name = "${local.common_tags.Environment}_consul_profile"
  role = aws_iam_role.allow_consul_s3.name
}

resource "aws_iam_role_policy" "allow_s3_all" {
  name = "${local.common_tags.Environment}_allow_s3_all"
  role = aws_iam_role.allow_consul_s3.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
                "arn:aws:s3:::*"
            ]
    }
  ]
}
EOF

}







# resource "aws_launch_configuration" "webapp_lc" {
#   lifecycle {
#     create_before_destroy = true
#   }

#   name_prefix   = "${terraform.workspace}-ddt-lc-"
#   image_id      = data.aws_ami.ubuntu.id
#   instance_type = local.asg_instance_size

#   security_groups = [
#     aws_security_group.consul_http_inbound_sg.id
#     aws_security_group.consul_ssh_inbound_sg.id,
#     aws_security_group.consul_sg.id,
#   ]

#   user_data                   = file("./templates/userdata.sh")
#   associate_public_ip_address = true
# }

# resource "aws_elb" "webapp_elb" {
#   name    = "ddt-webapp-elb-${terraform.workspace}"
#   subnets = slice(data.aws_availability_zones.available.names, 0, var.subnet_count)

#   listener {
#     instance_port     = 80
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }

#   health_check {
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 3
#     target              = "HTTP:80/"
#     interval            = 10
#   }

#   security_groups = [aws_security_group.consul_http_inbound_sg.id]

#   tags = local.common_tags
# }

# resource "aws_autoscaling_group" "webapp_asg" {
#   lifecycle {
#     create_before_destroy = false
#   }

#   vpc_zone_identifier   = slice(data.aws_availability_zones.available.names, 0, var.subnet_count)
#   name                  = "ddt_webapp_asg-${terraform.workspace}"
#   max_size              = local.asg_max_size
#   min_size              = local.asg_min_size
#   wait_for_elb_capacity = local.asg_min_size
#   force_delete          = true
#   launch_configuration  = aws_launch_configuration.webapp_lc.id
#   load_balancers        = [aws_elb.webapp_elb.name]

#   dynamic "tag" {
#     for_each = local.common_tags
#     content {
#       key                 = tag.key
#       value               = tag.value
#       propagate_at_launch = true
#     }
#   }
# }

# # Scale Up Policy
# #
# resource "aws_autoscaling_policy" "scale_up" {
#   name                   = "ddt_asg_scale_up-${terraform.workspace}"
#   scaling_adjustment     = 1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 300
#   autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
# }

# # Scale Down Policy and Alarm
# #
# resource "aws_autoscaling_policy" "scale_down" {
#   name                   = "ddt_asg_scale_down-${terraform.workspace}"
#   scaling_adjustment     = -1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 600
#   autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
# }








