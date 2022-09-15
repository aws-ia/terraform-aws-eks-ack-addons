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