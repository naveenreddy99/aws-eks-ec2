resource "aws_codepipeline" "ecs_codepipeline" {
  name     = "nginx-pipeline"
  role_arn = aws_iam_role.ecs_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.nginx_codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        RepositoryName = "nginx-docker"
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.nginx-to-ecr.name
      }
    }
  }
}

resource "aws_s3_bucket" "nginx_codepipeline_bucket" {
  bucket = "nginx-codebuild-bucket"
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.nginx_codepipeline_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "ecs_codepipeline_role" {
  name = "nginx-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "amazon-s3-full-codepipeline-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.ecs_codepipeline_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-cloudwatch-full-codepipeline-access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.ecs_codepipeline_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-codecommit-full-codepipeline-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
  role       = aws_iam_role.ecs_codepipeline_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-codepipeline-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipelineFullAccess"
  role       = aws_iam_role.ecs_codepipeline_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-codebuild-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
  role       = aws_iam_role.ecs_codepipeline_role.name
}

resource "aws_iam_role_policy_attachment" "amazon-ecs-full-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  role       = aws_iam_role.ecs_codepipeline_role.name
}