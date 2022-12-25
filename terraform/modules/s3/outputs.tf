# khai báo output lấy ra giá trị các thuộc tính của s3 bucket

output "bucket_name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.lab_bucket.id
}