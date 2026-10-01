
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "aws_linux_2_latest" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}