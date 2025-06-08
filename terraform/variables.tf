variable "tags" {
  description = "Default tags for all resources."
  type = object({
    environment = optional(string, "develop")
    product     = optional(string, "cloud")
    service     = optional(string, "pipeline")
  })
  default = {
    environment = "develop"
    product     = "cloud"
    service     = "pipeline"
  }
}

variable "domain_name" {
  description = "Domain name for the environment. Example: 'example.com'."
  type        = string

}

variable "email_alert" {
  description = "Email address for SNS alerts."
  type        = string
}

variable "account_id" {
  description = "AWS account ID for the environment."
  type        = string

}
