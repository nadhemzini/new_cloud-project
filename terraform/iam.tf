# ============================================================
# IAM — Using pre-existing AWS Academy LabRole
# No custom IAM roles (AWS Academy doesn't allow iam:CreateRole)
# ============================================================

# All IAM references use data sources from main.tf:
#   - data.aws_iam_role.lab_role
#   - data.aws_iam_instance_profile.lab_profile
#
# These are pre-created by AWS Academy and available in every lab session.
