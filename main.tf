
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# Load Balancer SG
resource "aws_security_group" "elb_sg" {
  name   = "elb_sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_elb" "elb" {
  name            = "elb"
  subnets         = data.aws_subnets.default_subnets.ids
  security_groups = [aws_security_group.elb_sg.id]
  instances       = values(aws_instance.http_servers).*.id


  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}


#  HTTP server -> 80 TCP 
#  sg -> 80 tcp, 22 tcp , CIDR ["0.0.0.0/0"]

resource "aws_security_group" "http_server_sg" {
  name   = "http_server_sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "http_server_sg_from_maruf_TF"
  }

}

resource "aws_instance" "http_servers" {
  # ami                    = "ami-0bf05131040dbf2fc"
  ami                    = data.aws_ami.aws_linux_2_latest.id
  key_name               = "default-ec2"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.http_server_sg.id]
  # subnet_id              = data.aws_subnets.default_subnets.ids[0]

  for_each  = toset(data.aws_subnets.default_subnets.ids)
  subnet_id = each.value

  tags = {
    name : "http_servers_${each.value}"
  }


  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(pathexpand(var.aws_key_pair))
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",                                                                                   # install httpd
      "sudo service httpd start",                                                                                    # start
      "echo Welcome to DevOpsLearning - Virtual Server is at ${self.public_dns} | sudo tee /var/www/html/index.html" # copy a file

    ]
  }

}



######################### UPDATES #######################

# # data "aws_subnets" "default_subnets" {
#   filter {
#     name   = "vpc-id"
#     values = [aws_default_vpc.default.id]
#   }
# }

# subnet_id = data.aws_subnets.default_subnets.ids[0]


# filter {
# name = "name"
# values = ["amzn2-ami-kernel-5.10-hvm*"]
# }

# filter {
# name = "architecture"
# values = ["x86_64"]
# }