variable "tags" {
  description = "Tags for the Jenkins VPC resources."
  type = object({
    environment = optional(string, "develop")
    product     = optional(string, "cloud")
    service     = optional(string, "pipeline")
  })
}
