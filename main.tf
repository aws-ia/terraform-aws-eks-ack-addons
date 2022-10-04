module "ack_apigw" {
  count         = var.enable_ack_apigw ? 1 : 0
  source        = "./modules/ack-apigw"
  helm_config   = var.ack_apigw_helm_config
  addon_context = local.addon_context
}

module "ack_dynamodb" {
  count         = var.enable_ack_dynamodb ? 1 : 0
  source        = "./modules/ack-dynamodb"
  helm_config   = var.ack_dynamodb_helm_config
  addon_context = local.addon_context
}

module "ack_s3" {
  count         = var.enable_ack_s3 ? 1 : 0
  source        = "./modules/ack-s3"
  helm_config   = var.ack_s3_helm_config
  addon_context = local.addon_context
}

module "ack_rds" {
  count         = var.enable_ack_rds ? 1 : 0
  source        = "./modules/ack-rds"
  helm_config   = var.ack_rds_helm_config
  addon_context = local.addon_context
}
