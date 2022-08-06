resource "aws_ecr_repository" "ecr_repository" {
  name                 = "${var.ecr_name}"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "aws_ecr_policy" {
  repository = aws_ecr_repository.ecr_repository.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}