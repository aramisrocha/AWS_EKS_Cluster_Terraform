variable "region" {
   default = "us-east-2"
   description = "Main region" 
}


variable "tag_name" {
  default = "dev"
}



#Neste laboratorio vamos utilizar VPcs e Subnets existentes, com isso vamos utilizar o data com os ids
# Os ids originais foram omitidos

data "aws_subnet" "subnet_1" {
  id = "subnetid"
}

data "aws_subnet" "subnet_2" {
  id = "subnetid"
}


data "aws_vpc" "vpc_1" {
  id = "vpcid"
}