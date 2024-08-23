
# Create a Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-postgres-sg"
  description = "Allow public access to PostgreSQL"
  vpc_id      = aws_vpc.main.id  # Ensure the VPC ID is correctly specified

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows public access (be cautious with this in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-postgres-sg"
  }
}

# Create a Subnet Group for RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "rds-subnet-group"
  }
}

# Create the RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier              = "my-postgres-db"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"  # Minimal size, change as needed
  allocated_storage       = 20             # Minimal size, change as needed
  db_name                 = "gantt"
  username                = "postgres"
  password                = "postgrespass"
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = true           # Public IP
  skip_final_snapshot     = true
  deletion_protection     = false

  monitoring_interval     = 60             # Enable enhanced monitoring (DB Insight)
  monitoring_role_arn     = aws_iam_role.rds_monitoring_role.arn

 # Enable logging
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"] # Logs to export to CloudWatch

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7  # Optional, retention period in days (7 is the default)

  tags = {
    Name = "my-postgres-db"
  }
}

# IAM Role for Enhanced Monitoring (DB Insight)
resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required policy for enhanced monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring_role_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
