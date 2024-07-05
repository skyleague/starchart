module "artifacts_bucket" {
  source = "git@github.com:skyleague/aws-s3.git?ref=v1.0.0"

  bucket_name_prefix = "${local.config.project_name}-artifacts"
}

output "artifacts_bucket_id" {
  value = module.artifacts_bucket.this.id
}
