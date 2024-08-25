
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

# # Create an RDS Aurora Serverless Cluster for PostgreSQL
# resource "aws_rds_cluster" "aurora_postgres" {
#   cluster_identifier      = "aurora-postgres-cluster"
#   engine                  = "aurora-postgresql"
#   engine_mode             = "provisioned"
#   engine_version          = "16.3"
#   database_name           = "gantt"
#   master_username         = "auroraadmin"
#   master_password         = "aurorapassword"
#   vpc_security_group_ids  = [aws_security_group.rds_sg.id]
#   db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name

#   serverlessv2_scaling_configuration {
#     max_capacity = 1.0
#     min_capacity = 0.5
#   }

#   skip_final_snapshot     = true
#   deletion_protection     = false

#   tags = {
#     Name = "aurora-postgres-cluster"
#   }
# }

# resource "aws_rds_cluster_instance" "aurora_instance" {
#   cluster_identifier = aws_rds_cluster.aurora_postgres.id
#   instance_class     = "db.serverless"
#   engine             = aws_rds_cluster.aurora_postgres.engine
#   engine_version     = aws_rds_cluster.aurora_postgres.engine_version
# }

# # Create an IAM Role for RDS Proxy
# resource "aws_iam_role" "rds_proxy_role" {
#   name = "rds-proxy-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "rds.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Attach the correct policy for RDS Proxy to the IAM Role
# resource "aws_iam_role_policy_attachment" "rds_proxy_role_policy" {
#   role       = aws_iam_role.rds_proxy_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
# }

# # Create an RDS Proxy for Aurora PostgreSQL
# resource "aws_db_proxy" "aurora_proxy" {
#   name                   = "aurora-postgres-proxy"
#   engine_family          = "POSTGRESQL"
#   require_tls            = true
#   idle_client_timeout    = 1800
#   debug_logging          = false
#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
#   vpc_subnet_ids         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

#   role_arn               = aws_iam_role.rds_proxy_role.arn  # Specify the role ARN

#   auth {
#     auth_scheme = "SECRETS"
#     description = "Aurora RDS Proxy"
#     iam_auth    = "DISABLED"
#     secret_arn  = aws_secretsmanager_secret.aurora_secret.arn
#   }

#   tags = {
#     Name = "aurora-postgres-proxy"
#   }
# }

# # Create Secrets Manager Secret for RDS Proxy
# resource "aws_secretsmanager_secret" "aurora_secret" {
#   name = "aurora-secret"

#   tags = {
#     Name = "aurora-secret"
#   }
# }

# # Store the secret value in Secrets Manager
# resource "aws_secretsmanager_secret_version" "aurora_secret_value" {
#   secret_id     = aws_secretsmanager_secret.aurora_secret.id
#   secret_string = jsonencode({
#     username = "auroraadmin"
#     password = "aurorapassword"
#   })
# }

