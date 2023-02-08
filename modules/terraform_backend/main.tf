#   ____ _____   _                _        _
#  / ___|___ /  | |__  _   _  ___| | _____| |_
#  \___ \ |_ \  | '_ \| | | |/ __| |/ / _ \ __|
#   ___) |__) | | |_) | |_| | (__|   <  __/ |_
#  |____/____/  |_.__/ \__,_|\___|_|\_\___|\__|

resource "aws_s3_bucket" "terraform_backend" {
  bucket = "${var.app}-terraform-backend"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name       = var.app
    CostCenter = var.app
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.terraform_backend.bucket

  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_backend_access" {
  bucket = aws_s3_bucket.terraform_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_backend_versioning" {
  bucket = aws_s3_bucket.terraform_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

#   ____                                    ____  ____    _            _
#  |  _ \ _   _ _ __   __ _ _ __ ___   ___ |  _ \| __ )  | | ___   ___| | __
#  | | | | | | | '_ \ / _` | '_ ` _ \ / _ \| | | |  _ \  | |/ _ \ / __| |/ /
#  | |_| | |_| | | | | (_| | | | | | | (_) | |_| | |_) | | | (_) | (__|   <
#  |____/ \__, |_| |_|\__,_|_| |_| |_|\___/|____/|____/  |_|\___/ \___|_|\_\
#         |___/

resource "aws_dynamodb_table" "terraform_backend_lock" {
  name             = "${var.app}-terraform-backend-lock"
  hash_key         = "LockID"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name       = var.app
    CostCenter = var.app
  }
}
