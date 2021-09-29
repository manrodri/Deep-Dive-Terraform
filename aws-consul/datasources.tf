### instance


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# VPC
data "aws_availability_zones" "available" {}



# data "template_file" "userdata" {
#   template = file("templates/userdata.sh")

#   vars = {
#     wp_db_hostname      = aws_db_instance.rds.endpoint
#     wp_db_name          = "${terraform.workspace}${local.rds_db_name}"
#     wp_db_user          = var.rds_username
#     wp_db_password      = var.rds_password
#     playbook_repository = var.playbook_repository
#   }
# }
