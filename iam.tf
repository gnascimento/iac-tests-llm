# Define the policy to allow full access to all S3 actions and resources
resource "aws_iam_policy" "s3_full_access_policy" {
  name        = "S3FullAccessPolicy"
  description = "Policy to allow full access to all S3 actions and resources"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = "${aws_s3_bucket.bucket_for_website.arn}"
      }
    ]
  })
}

# Reference an existing IAM user
data "aws_iam_user" "user" {
  user_name = "admin" # Replace with the existing username
}

resource "aws_iam_user_policy_attachment" "attach_s3_full_access_policy" {
  user       = data.aws_iam_user.user.user_name
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
}


resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.bucket_for_website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.bucket_for_website.arn}/*"
      }
    ]
  })
}
