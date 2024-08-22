resource "aws_ecr_repository" "gantt" {
  name                 = "gantt"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Environment = "poc"
    Name        = "gantt-repository"
  }
}