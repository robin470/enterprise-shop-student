terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-2"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  project = "enterprise-shop"

  repositories = toset([
    "api-gateway",
    "user-service",
    "product-service",
    "order-service",
    "payment-service",
    "notification-service",
    "frontend"
  ])
}

# Networking: public subnets, no NAT Gateway
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "${local.project}-vpc"
  cidr = "10.0.0.0/16"

  azs            = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true

  tags = {
    Project = local.project
  }
}

# EKS cluster and managed worker nodes
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  cluster_name = "${local.project}-cluster"
  
  enable_irsa = false

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    main = {
      name           = "shop-workers"
      iam_role_name  = "shop-node-role"
      instance_types = ["m7i-flex.large"]

      min_size     = 1
      max_size     = 1
      desired_size = 1

      network_interfaces = [
        {
          associate_public_ip_address = true
        }
      ]
    }
  }

  tags = {
    Project = local.project
  }
}

# Seven private ECR repositories for our application images
resource "aws_ecr_repository" "app" {
  for_each = local.repositories

  name                 = "${local.project}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = local.project
  }
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_urls" {
  value = {
    for name, repo in aws_ecr_repository.app :
    name => repo.repository_url
  }
}

output "region" {
  value = "us-east-2"
}
