data "aws_caller_identity" "current" {}

locals {
  animal_media_bucket_name     = "bestbuddy-animal-media-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  animal_media_service_account = "bestbuddy-api"
}

resource "aws_s3_bucket" "animal_media" {
  bucket = local.animal_media_bucket_name
}

resource "aws_s3_bucket_public_access_block" "animal_media" {
  bucket                  = aws_s3_bucket.animal_media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "animal_media" {
  bucket = aws_s3_bucket.animal_media.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "animal_media" {
  bucket = aws_s3_bucket.animal_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "animal_media" {
  bucket = aws_s3_bucket.animal_media.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "animal_media_require_tls" {
  bucket = aws_s3_bucket.animal_media.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.animal_media.arn,
        "${aws_s3_bucket.animal_media.arn}/*",
      ]
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}

resource "aws_iam_role" "animal_media" {
  name = "${var.cluster_name}-animal-media"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
    }]
  })
}

resource "aws_iam_role_policy" "animal_media" {
  name = "${var.cluster_name}-animal-media"
  role = aws_iam_role.animal_media.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
      ]
      Resource = "${aws_s3_bucket.animal_media.arn}/*"
    }]
  })
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = module.eks.cluster_name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_eks_pod_identity_association" "animal_media" {
  cluster_name    = module.eks.cluster_name
  namespace       = "default"
  service_account = local.animal_media_service_account
  role_arn        = aws_iam_role.animal_media.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy.animal_media,
  ]
}

output "animal_media_bucket_name" {
  description = "Private S3 bucket used for uploaded animal photos"
  value       = aws_s3_bucket.animal_media.bucket
}
