
################################################################################
# GitOps Bridge
################################################################################
/*
This output is intended to be used with GitOps when the addons' Helm charts
are going to be installed by a GitOps tool such as ArgoCD or FluxCD.
We guarantee that this output will be maintained any time a new addon is
added or an addon is updated, and new metadata for the Helm chart is needed.
*/
output "gitops_metadata" {
  description = "GitOps Bridge metadata"
  value = merge(
    { for k, v in {
      iam_role_arn    = module.sns.iam_role_arn
      namespace       = try(var.sns.namespace, "ack-system")
      service_account = local.sns_name
      } : "ack_iam_${k}" => v if var.enable_sns
    },
    { for k, v in {
      iam_role_arn    = module.sqs.iam_role_arn
      namespace       = try(var.sqs.namespace, "ack-system")
      service_account = local.sqs_name
      } : "ack_iam_${k}" => v if var.enable_sqs
    },
    { for k, v in {
      iam_role_arn    = module.lambda.iam_role_arn
      namespace       = try(var.lambda.namespace, "ack-system")
      service_account = local.lambda_name
      } : "ack_iam_${k}" => v if var.enable_lambda
    },
    { for k, v in {
      iam_role_arn    = module.iam.iam_role_arn
      namespace       = try(var.iam.namespace, "ack-system")
      service_account = local.iam_name
      } : "ack_iam_${k}" => v if var.enable_iam
    },
    { for k, v in {
      iam_role_arn    = module.ec2.iam_role_arn
      namespace       = try(var.ec2.namespace, "ack-system")
      service_account = local.ec2_name
      } : "ack_ec2_${k}" => v if var.enable_ec2
    },
    { for k, v in {
      iam_role_arn    = module.eks.iam_role_arn
      namespace       = try(var.eks.namespace, "ack-system")
      service_account = local.eks_name
      } : "ack_eks_${k}" => v if var.enable_eks
    },
    { for k, v in {
      iam_role_arn    = module.kms.iam_role_arn
      namespace       = try(var.kms.namespace, "ack-system")
      service_account = local.kms_name
      } : "ack_kms_${k}" => v if var.enable_kms
    },
    { for k, v in {
      iam_role_arn    = module.acm.iam_role_arn
      namespace       = try(var.acm.namespace, "ack-system")
      service_account = local.acm_name
      } : "ack_acm_${k}" => v if var.enable_acm
    },
    { for k, v in {
      iam_role_arn    = module.apigatewayv2.iam_role_arn
      namespace       = try(var.apigatewayv2.namespace, "ack-system")
      service_account = local.apigatewayv2_name
      } : "ack_apigatewayv2_${k}" => v if var.enable_apigatewayv2
    },
    { for k, v in {
      iam_role_arn    = module.dynamodb.iam_role_arn
      namespace       = try(var.dynamodb.namespace, "ack-system")
      service_account = local.dynamodb_name
      } : "ack_dynamodb_${k}" => v if var.enable_dynamodb
    },
    { for k, v in {
      iam_role_arn    = module.s3.iam_role_arn
      namespace       = try(var.s3.namespace, "ack-system")
      service_account = local.s3_name
      } : "ack_s3_${k}" => v if var.enable_s3
    },
    { for k, v in {
      iam_role_arn    = module.rds.iam_role_arn
      namespace       = try(var.rds.namespace, "ack-system")
      service_account = local.rds_name
      } : "ack_rds_${k}" => v if var.enable_rds
    },
    { for k, v in {
      iam_role_arn    = module.prometheusservice.iam_role_arn
      namespace       = try(var.prometheusservice.namespace, "ack-system")
      service_account = local.prometheusservice_name
      } : "ack_prometheusservice_${k}" => v if var.enable_prometheusservice
    },
    { for k, v in {
      iam_role_arn    = module.emrcontainers.iam_role_arn
      namespace       = try(var.emrcontainers.namespace, "ack-system")
      service_account = local.emrcontainers_name
      } : "ack_emrcontainers_${k}" => v if var.enable_emrcontainers
    },
    { for k, v in {
      iam_role_arn    = module.sfn.iam_role_arn
      namespace       = try(var.sfn.namespace, "ack-system")
      service_account = local.sfn_name
      } : "ack_sfn_${k}" => v if var.enable_sfn
    },
    { for k, v in {
      iam_role_arn    = module.eventbridge.iam_role_arn
      namespace       = try(var.eventbridge.namespace, "ack-system")
      service_account = local.eventbridge_name
      } : "ack_eventbridge_${k}" => v if var.enable_eventbridge
    },
    { for k, v in {
      iam_role_arn    = module.elasticache.iam_role_arn
      namespace       = try(var.elasticache.namespace, "ack-system")
      service_account = local.elasticache_name
      } : "ack_elasticache_${k}" => v if var.enable_elasticache
    }
  )
}
