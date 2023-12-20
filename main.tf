#Criando um VPC
provider "aws" {
  region = "${var.region}"
}


terraform {
 
 #Backend para subir os arquivos no 
 
  backend "s3" {
    bucket = "aramis-aws-terraform-remote-state-dev"
    key    = "ec2/ec2provider.tfstate"
    region = "us-east-2"
  }
}