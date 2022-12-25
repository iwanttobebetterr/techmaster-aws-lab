# gọi module s3 từ đường dẫn local và truyền các giá trị vào
module "s3_bucket" {
  source = "../modules/s3"

  bucket_name = "techmaster-aws-07-${var.env}"

  tags = {
    Env = var.env
  }
}

# in ra output của s3 module
output "s3_bucket_name" {
  value = module.s3_bucket.bucket_name
}