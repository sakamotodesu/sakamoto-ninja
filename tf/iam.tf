data "aws_iam_user" "sakamoto" {
  user_name = "sakamoto"
}

resource "aws_iam_user" "sakamoto-ninja-s3-update" {
  name = "sakamoto-ninja-s3-update"
  tags = {
    Service = "sakamoto-ninja"
  }
}

resource "aws_iam_user_policy" "sakamoto-ninja-s3-update-policy" {
  name = "sakamoto-ninja-s3-policy"
  user = aws_iam_user.sakamoto-ninja-s3-update.name
  policy = data.aws_iam_policy_document.sakamoto-ninja-s3-update.json
}

data "aws_iam_policy_document" "sakamoto-ninja-s3-update" {
  version = "2012-10-17"

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.sakamoto-ninja-site.arn,
      "${aws_s3_bucket.sakamoto-ninja-site.arn}/*",
    ]
    sid = "VisualEditor0"
  }
}