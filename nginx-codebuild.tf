resource "aws_iam_role" "code-build" {
  name = "ecs-code-build-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "amazon-ec2-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.code-build.name
}

resource "aws_iam_role_policy_attachment" "amazon-codecommit-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
  role       = aws_iam_role.code-build.name
}

resource "aws_iam_role_policy_attachment" "amazon-ec2-container-reg-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.code-build.name
}

resource "aws_iam_role_policy_attachment" "amazon-s3-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.code-build.name
}

resource "aws_iam_role_policy_attachment" "amazon-cloudwatch-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.code-build.name
}

resource "aws_iam_role_policy_attachment" "amazon-codebuild-admin-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
  role       = aws_iam_role.code-build.name
}

resource "aws_iam_role_policy" "eks_describe" {
  name = "eksDescribeCluster"
  role = aws_iam_role.code-build.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_security_group" "nginx_codebuild" {
  name   = "nginx-codebuild-${var.environment}-gs"
  vpc_id = aws_vpc.main.id

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_codebuild_project" "nginx-to-ecr" {
  name          = "nginx-ecr-ecr-deployment"
  description   = "nginx_codebuild_project"
  build_timeout = "60"
  service_role  = aws_iam_role.code-build.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "103750175519"
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.ecr_repository.name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = var.codecommit_url
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "main"

  vpc_config {
    vpc_id = aws_vpc.main.id

    subnets = [
      aws_subnet.private.0.id,
      aws_subnet.private.1.id
    ]

    security_group_ids = ["${aws_security_group.nginx_codebuild.id}"]
  }

  tags = {
    Environment = "Test"
  }
}