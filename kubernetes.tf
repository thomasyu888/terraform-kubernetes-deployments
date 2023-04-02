terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.48.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
  }
}

data "tfe_outputs" "eks" {
  organization = "sage-bionetworks"
  workspace = "learn-terraform-eks"
}

# data "terraform_remote_state" "eks" {
#   backend = "local"

#   config = {
#     path = "../learn-terraform-provision-eks-cluster/terraform.tfstate"
#   }
# }

# Retrieve EKS cluster information
provider "aws" {
  profile                  = "dnt"
  region = data.tfe_outputs.eks.values.region
}

data "aws_eks_cluster" "cluster" {
  name = data.tfe_outputs.eks.values.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name,
      "--profile",
      "dnt"
    ]
  }
}

resource "kubernetes_deployment" "schematic" {
  metadata {
    name = "scalable-schematic-example"
    labels = {
      App = "ScalableSchematicExample"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "ScalableSchematicExample"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableSchematicExample"
        }
      }
      spec {
        container {
          image = "ghcr.io/sage-bionetworks/schematic:0.1.37-beta"
          name  = "schematic"

          port {
            container_port = 7080
          }
          env {
            name = "SERVICE_ACCOUNT_CREDS"
            value_from {
              secret_key_ref {
                name = "schematic-env"
                key = "SERVICE_ACCOUNT_CREDS"
              }
            }
          }
          resources {
            limits = {
              cpu    = "1"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "schematic" {
  metadata {
    name = "schematic-example"
  }
  spec {
    selector = {
      App = kubernetes_deployment.schematic.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 7080
      target_port = 7080
    }

    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = kubernetes_service.schematic.status.0.load_balancer.0.ingress.0.hostname
}