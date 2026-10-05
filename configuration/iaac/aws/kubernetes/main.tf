terraform {
  required_version = ">= 1.5"
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.30" }
  }
  backend "s3" {
    bucket       = "terraform-backend-state-270485099150"
    key          = "eks/in28minutes/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_default_vpc" "default" {}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }

  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "in28minutes-cluster"
  cluster_version = "1.31" # use a currently supported version
  vpc_id          = aws_default_vpc.default.id
  subnet_ids      = data.aws_subnets.subnets.ids

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 3
      desired_size   = 3
      max_size       = 5
    }
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}