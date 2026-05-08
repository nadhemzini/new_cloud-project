# ============================================================
# ec2_app.tf — REPLACED by new separated architecture
#
# This file previously contained a single unified EC2 instance
# running both frontend and backend together.
#
# It has been replaced by:
#   - frontend_ec2.tf     → dedicated Frontend EC2 (public subnet)
#   - launch_template.tf  → Backend Launch Template (private subnet)
#   - asg.tf              → Auto Scaling Group (min=2, max=4)
#   - security_groups.tf  → separated ALB/Backend/RDS/Frontend SGs
#
# All resources from this file have been moved to the files above.
# DO NOT re-add resources here — it will cause duplicate resource errors.
# ============================================================
