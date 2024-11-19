data "tls_certificate" "identity" {
  url = var.svc_eks_cluster_oidc_issuer
  # data.terraform_remote_state.eks.outputs.eks_cluster_oidc_issuer 
  # module.eks.cluster_oidc_issuer_url
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.identity.certificates[0].sha1_fingerprint]
  url             = var.svc_eks_cluster_oidc_issuer
  tags = {
    Name = "${var.prefix}-oidc"
  }  
}

resource "aws_iam_policy" "service_account_policy" {
  name        = "${var.prefix}-service-account-policy"
  path        = "/"
  description = "service account policy for cluster-autoscaler"
  tags = {
    Name = "${var.prefix}-amap-service-account-policy"
  }  

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "service_account_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name = "${var.prefix}-service-account-role-"
  tags = {
    Name = "${var.prefix}-service-account-role"
  }  
}

resource "aws_iam_policy_attachment" "attach-policy" {
  name       = "${var.prefix}-service_acount-policy-attachment"
  roles      = [aws_iam_role.service_account_role.name]
  policy_arn = aws_iam_policy.service_account_policy.arn
}

variable "prefix" {
    description = "environment"
}