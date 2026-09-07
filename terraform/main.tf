terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "complex" {
  name        = "complex"
  description = "Aplicação multi-container do projeto CI/CD"
}

resource "aws_vpc" "complex" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "complex-vpc"
  }
}
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.complex.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "complex-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.complex.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "complex-public-b"
  }
}
resource "aws_internet_gateway" "complex" {
  vpc_id = aws_vpc.complex.id

  tags = {
    Name = "complex-igw"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.complex.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.complex.id
  }

  tags = {
    Name = "complex-public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_elastic_beanstalk_environment" "complex" {
  name                = "complex-env"
  application         = aws_elastic_beanstalk_application.complex.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.7.7 running ECS"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.complex.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.public_a.id},${aws_subnet.public_b.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public_a.id},${aws_subnet.public_b.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "public"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }
}
resource "aws_s3_bucket" "beanstalk" {
  bucket_prefix = "complex-beanstalk-"

  tags = {
    Name = "complex-beanstalk"
  }
}

resource "aws_s3_object" "dockerrun" {
  bucket = aws_s3_bucket.beanstalk.id
  key    = "Dockerrun.aws.json"
  source = "${path.module}/../Dockerrun.aws.json"

  etag = filemd5("${path.module}/../Dockerrun.aws.json")
}
output "beanstalk_bucket_name" {
  value = aws_s3_bucket.beanstalk.bucket
}