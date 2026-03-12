variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
}

variable "instance_count" {
  default = 3
}

variable "app_port" {
  default = 8000
}
