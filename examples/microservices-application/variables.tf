# tflint-ignore: terraform_unused_declarations
variable "cluster_name" {
  description = "Name of cluster - used by Terratest for e2e test automation"
  type        = string
  default     = "ack-demo"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}
