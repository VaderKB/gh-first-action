terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"

  tags = {
    Name = "tf_allow_data"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "${var.cidr_block}/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
} 

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "${var.cidr_block}/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
} 


# Generate a new SSH key pair locally
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "tf_key_pair"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# output "path_module_val" {
#   value = aws_key_pair.deployer.key_name
# }

resource "local_file" "private_key" {
  content = tls_private_key.ec2_key.private_key_pem
  filename = "${path.module}/my-ec2-key.pem"
}

resource "aws_instance" "myec2" {
  ami           = var.ami_value
  instance_type = var.instance_type
  tags = {
    Name = var.instance_name
  }
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids  = [aws_security_group.allow_tls.id]
}

output "myEc2Ip" {
  value = aws_instance.myec2.public_ip
}