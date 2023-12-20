# Este documento contém o codigo em terraform para subir um cluster kubernets inicialmente com tres nos
# todas as potiticas relacionadas a este cluster foram devidamente confifurada


# Role destinada as permissoes do lLuster
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}





# Recurso para criar um papel IAM para os worker nodes
resource "aws_iam_role" "eks_nodes" {
  name = "eks-nodes-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


# Recurso para criar um cluster EKS
resource "aws_eks_cluster" "cluster-dev" {
  name     = "cluster-dev"
  role_arn = aws_iam_role.eks_cluster.arn
  vpc_config {
    security_group_ids = [aws_security_group.cluster.id]
    subnet_ids = [
      data.aws_subnet.subnet_1.id,
      data.aws_subnet.subnet_2.id,
    ]
  }
  # Precisei adicionar o depends, pois estava ocorrendo problema na hora de subir o cluster
  depends_on = [
    aws_iam_role_policy_attachment.attach_eks_cluster_policy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.wordnode_policy,
  ]
  tags = {
    name = var.tag_name
  }
}


# Nesta seção é onde é denifindo a quantidade, tipo e outras configurações relacionados aos Nodes
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.cluster-dev.name
  node_group_name = "eks-nodes"
  subnet_ids      = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id]
  node_role_arn   = aws_iam_role.eks_nodes.arn
  capacity_type   = "ON_DEMAND"
  instance_types  = ["t3.medium"]
  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 3
  }
  tags = {
    name = var.tag_name
  }
}

# Abaixo foram adicionados todas as politicas ao roles que sao necessarios para subir o cluster
resource "aws_iam_role_policy_attachment" "attach_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "wordnode_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}


#  Criando o security group que sera atribuido ao cluster limitando o acesso somente da rede interna
resource "aws_security_group" "cluster" {
  name        = "terraform_cluster"
  description = "AWS security group for terraform"
  vpc_id      = data.aws_vpc.vpc_1.id

  # Input
  ingress {
    from_port   = "1"
    to_port     = "65365"
    protocol    = "TCP"
    cidr_blocks = concat(data.aws_subnet.subnet_1[*].cidr_block, data.aws_subnet.subnet_2[*].cidr_block, [data.aws_vpc.vpc_1.cidr_block])
  }

  # Output
  egress {
    from_port   = 0             # any port
    to_port     = 0             # any port
    protocol    = "-1"          # any protocol
    cidr_blocks = ["0.0.0.0/0"] # any destination
  }

  # ICMP Ping 
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = concat(data.aws_subnet.subnet_1[*].cidr_block, data.aws_subnet.subnet_2[*].cidr_block, [data.aws_vpc.vpc_1.cidr_block])
  }
  tags = {
    name = var.tag_name
  }
}