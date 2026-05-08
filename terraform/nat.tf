# ============================================================
# NAT Gateway — placed in public subnet AZ-A
# Private subnets route outbound traffic through it
# (Backend instances need this to: git clone, pull docker images, etc.)
# ============================================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id   # public subnet in us-east-1a

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-gw"
  }
}
