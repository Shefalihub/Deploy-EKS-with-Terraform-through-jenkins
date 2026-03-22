provider "aws" {
    region = "us-east-1"
  
}

# eks cluster create
resource "aws_iam_role" "cluster" {
    name = "eks-cluster"
    assume_role_policy = jsondecode({
        Version ="2012-10-17"
        Statement = [
            {
                Action = [
                    "sts:AssumeRole",
                    "sts:TagSession"
                ]
                Effect = "Allow"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            },
        ]
    })
}

# attach policy
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role =  aws_iam_role.cluster.name
}

# default vpc
data "aws_vpc" "default" {
    default = true
  
}

# choosen subnet with particular az zone
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b"]
  }
}

# configuration of cluster
resource "aws_eks_cluster" "cluster" {
    name = "cluster"
    access_config {
        authentication_mode = "API"
      }
      role_arn = aws_iam_role.cluster.arn
      vpc_config {
        subnet_ids = data.aws_subnets.default.ids
      }
      depends_on = [ 
        aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
       ]
    }


    # add node groups

    # add policy for node group

    resource "aws_iam_role" "node-cluster" {
  name = "node-cluster"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-cluster.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       =  aws_iam_role.node-cluster.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       =  aws_iam_role.node-cluster.name
}





   resource "aws_eks_node_group" "node-cluster" {

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "node-cluster"
  node_role_arn   = aws_iam_role.node-cluster.arn

  subnet_ids = data.aws_subnets.default.ids

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]
}
