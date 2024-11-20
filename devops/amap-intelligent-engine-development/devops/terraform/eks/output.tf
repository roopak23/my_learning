output "eks_cluster_name" {
  description = "eks cluster name"
    value = module.eks.cluster_id
}

output "eks_cluster_security_groups" {
    description = "eks security group"
    value = module.eks.worker_security_group_id
}

output "eks_cluster_oidc_issuer" {
 description = "identity"
 value = module.eks.cluster_oidc_issuer_url
}

output "region" {
  description = "eks cluster region"
  value = var.aws_region
}
