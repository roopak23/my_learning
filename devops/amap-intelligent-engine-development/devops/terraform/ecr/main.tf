resource "aws_ecr_repository" "airflow_repository" {
  name                 = "airflow"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type  = "KMS"
  }

  tags = {
    Name = "airflow"
  }
}

resource "aws_ecr_repository" "nifi_repository" {
  name                 = "nifi"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type  = "KMS"
  }

  tags = {
    Name = "nifi"
  }
}


resource "aws_ecr_repository" "order-management" {
  name                 = "order-management"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type  = "KMS"
  }

  tags = {
    Name = "order-management"
  }
}


resource "aws_ecr_repository" "inventory-management" {
  name                 = "inventory-management"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type  = "KMS"
  }

  tags = {
    Name = "inventory-management"
  }
}
