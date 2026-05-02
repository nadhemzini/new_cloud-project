# ============================================================
# S3 — MANAGED VIA AWS CLI (not Terraform)
# ============================================================
# AWS Academy explicitly denies s3:GetBucketObjectLockConfiguration
# which Terraform's AWS provider requires. Frontend S3 bucket is
# created and managed via the deploy-frontend.sh script instead.
#
# To create the bucket manually:
#   aws s3 mb s3://cloud-stack-sandbox-frontend-975050177113 --region us-east-1
#   aws s3 website s3://cloud-stack-sandbox-frontend-975050177113 --index-document index.html --error-document index.html
# ============================================================
