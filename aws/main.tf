
terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">=3.3.0"
        }
        random = {
            source = "hashicorp/random"
        }
    }
    required_version = ">= 0.13"

    backend "s3" {
        bucket = "pulsar-stack"
        key    = "pulsar/state"
        region = "us-east-2"
    }
}

provider "aws" {
    region  = var.region
}

data "aws_ami" "rhel_9" {
    most_recent      = true
    owners           = ["amazon", "aws-marketplace"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-5.10-hvm-2.0.20230119.1-x86_64-gp2"]
    }
}

resource "random_id" "key_pair_name" {
    byte_length = 4
    prefix      = "${var.key_name_prefix}-"
}

resource "aws_key_pair" "default" {
    key_name   = random_id.key_pair_name.hex
    public_key = file(var.public_key_path)
}

resource "aws_instance" "zookeeper" {
    ami                    = data.aws_ami.rhel_9.id
    instance_type          = var.instance_types["zookeeper"]
    key_name               = aws_key_pair.default.id
    subnet_id              = aws_subnet.default.id

    vpc_security_group_ids = [aws_security_group.default.id]
    
    count                  = var.num_zookeeper_nodes

    tags = {
        Name = "zookeeper-${count.index + 1}"
    }
}


resource "aws_instance" "bookie" {
    ami           = data.aws_ami.rhel_9.id
    instance_type = var.instance_types["bookie"]
    key_name               = aws_key_pair.default.id
    subnet_id              = aws_subnet.default.id

    vpc_security_group_ids = [aws_security_group.default.id]

    count         = var.num_bookie_nodes

    tags = {
        Name = "bookie-${count.index + 1}"
    }
}

resource "aws_instance" "broker" {
    ami                    = data.aws_ami.rhel_9.id
    instance_type          = var.instance_types["broker"]
    key_name               = aws_key_pair.default.id
    subnet_id              = aws_subnet.default.id

    vpc_security_group_ids = [aws_security_group.default.id]

    count                  = var.num_broker_nodes

    tags = {
        Name = "broker-${count.index + 1}"
    }
}

resource "aws_instance" "proxy" {
    ami                    = data.aws_ami.rhel_9.id
    instance_type          = var.instance_types["proxy"]
    key_name               = aws_key_pair.default.id
    subnet_id              = aws_subnet.default.id

    vpc_security_group_ids = [aws_security_group.default.id]

    count                  = var.num_proxy_nodes

    tags = {
        Name = "proxy-${count.index + 1}"
    }
}
