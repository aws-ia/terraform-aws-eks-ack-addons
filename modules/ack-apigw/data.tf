data "aws_iam_policy_document" "apigw_fullaccess" {
  statement {
    effect = "Allow"
    actions = [
      "execute-api:Invoke",
      "execute-api:ManageConnections"
    ]
    resources = ["arn:aws:execute-api:*:*:*"]
  }
}

data "aws_iam_policy_document" "apigw_admin" {
  statement {
    effect = "Allow"
    actions = [
      "apigateway:*"
    ]
    resources = ["arn:aws:apigateway:*::/*"]
  }
}
