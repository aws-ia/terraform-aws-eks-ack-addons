module "ack-apigw" {
  count         = var.enable_ack-apigw ? 1 : 0
  source        = "./modules/ack-apigw"
  helm_config   = var.ack-apigw_helm_config
  addon_context = local.addon_context
}

module "ack-dynamo" {
  count         = var.enable_ack-dynamodb? 1 : 0
  source        = "./modules/ack-dynamo"
  helm_config   = var.ack-dynamo_helm_config
  addon_context = local.addon_context
}

module "ack-s3" {
  count         = var.enable_ack-s3? 1 : 0
  source        = "./modules/ack-s3"
  helm_config   = var.ack-s3_helm_config
  addon_context = local.addon_context
}

module "ack-rds" {
  count         = var.enable_ack-rds? 1 : 0
  source        = "./modules/ack-rds"
  helm_config   = var.ack-rds_helm_config
  addon_context = local.addon_context
}