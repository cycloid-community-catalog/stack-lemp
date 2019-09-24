#
# IAM
#

# Ses policy
data "aws_iam_policy_document" "ses" {
  count = var.create_ses_access ? 1 : 0

  statement {
    actions = [
      "ses:ListIdentities",
      "ses:SendEmail",
    ]

    effect = "Allow"

    resources = [
      "${var.ses_resource_arn}",
    ]
  }
}

resource "aws_iam_policy" "ses" {
  count       = var.create_ses_access ? 1 : 0
  name        = "${var.project}-${var.env}-ses_access"
  description = "Grant ses access on ${var.ses_resource_arn}"
  policy      = data.aws_iam_policy_document.ses[0].json
}

resource "aws_iam_user" "ses" {
  count = var.create_ses_access ? 1 : 0
  name  = "ses-${var.project}-${var.env}"
  path  = "/"
}

resource "aws_iam_access_key" "ses" {
  count = var.create_ses_access ? 1 : 0
  user  = aws_iam_user.ses[0].name
}

resource "aws_iam_user_policy_attachment" "ses_access" {
  count      = var.create_ses_access ? 1 : 0
  user       = aws_iam_user.ses[0].name
  policy_arn = aws_iam_policy.ses[0].arn
}

output "iam_ses_user_key" {
  value = aws_iam_access_key.ses[0].id
}

output "iam_ses_user_secret" {
  value = aws_iam_access_key.ses[0].secret
}

# Allow front to send email directly
resource "aws_iam_policy_attachment" "ses_access" {
  count       = var.create_ses_access ? 1 : 0
  name       = "${var.env}-${var.project}-ses_access"
  roles      = [aws_iam_role.front.name]
  policy_arn = aws_iam_policy.ses[0].arn
}
