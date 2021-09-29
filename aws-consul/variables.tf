variable "region" {
  default = "eu-west-1"
}

variable "profile" {
}

variable "private_subnets" {
  type = list(any)
}

variable "public_subnets" {
  type = list(any)
}

variable "cidr_block" {
}

variable "subnet_count" {
}

# instance

variable "key_name" {

}

variable "private_key_path" {

}

##################################################################################
# LOCALS
##################################################################################

locals {
  asg_instance_size = var.asg_instance_size
  asg_max_size      = var.asg_max_size
  asg_min_size      = var.asg_min_size

  common_tags = {
    Environment = "Development"
    Team        = "SysOps"
  }
}


###### application

variable "ip_range" {
  default = "0.0.0.0/0"
}

variable "asg_instance_size" {
  default = "t2.micro"
}

variable "asg_max_size" {
  default = "2"
}

variable "asg_min_size" {
  default = "1"
}



