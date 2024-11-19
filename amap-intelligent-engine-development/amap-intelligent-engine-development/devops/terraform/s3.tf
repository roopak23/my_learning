


module "s3_data" {
  source          = "./s3"
  aws_region      = var.aws_region
  vpc_id          = var.network.vpc_id
  bucket_name     = "${var.prefix}-s3-data"
  env             = var.env
  prefix          = var.prefix
  aws_account_num = var.aws_account_num
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_data_rules" {
  bucket = module.s3_data.bucket_name

  rule {

    id     = "data-imported-csv"
    status = "Enabled"


    expiration {
      days = 180
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    filter {
      prefix = "data/inbound/"
    }


  }

  rule {
    id     = "data-exported"
    status = "Enabled"
    expiration {
      days = 180
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }


    filter {
      prefix = "data/outbound/"
    }


  }

  rule {


    id     = "ml-models-buckup-cleanup"
    status = "Enabled"
    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    filter {
      prefix = "data/ml_models/backup/"
    }

  }
  rule {
    id     = "ml-model-versions-cleanup"
    status = "Enabled"

    filter {
      prefix = "data/ml_models/"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }


  }
}


module "s3_logs" {
  source          = "./s3"
  aws_region      = var.aws_region
  vpc_id          = var.network.vpc_id
  bucket_name     = "${var.prefix}-s3-logs"
  env             = var.env
  prefix          = var.prefix
  aws_account_num = var.aws_account_num
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_logs_rules" {
  bucket = module.s3_logs.bucket_name

  rule {
    id     = "bucket-global"
    status = "Enabled"

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 14
    }

  }

}

module "s3_app" {
  source          = "./s3"
  aws_region      = var.aws_region
  vpc_id          = var.network.vpc_id
  bucket_name     = "${var.prefix}-s3-app"
  env             = var.env
  prefix          = var.prefix
  aws_account_num = var.aws_account_num
}



resource "aws_s3_bucket_lifecycle_configuration" "s3_app_rules" {
  bucket = module.s3_app.bucket_name

  rule {
    id     = "bucket-global"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 14
    }

  }

}

