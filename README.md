# Terraform Structure and Standards

## Organization Standard

This project follows a modular and layered approach for Terraform code organization, aiming for clarity, maintainability, and ease of peer review.

### Directory Structure

```
.
├── Dockerfile                  # Custom Docker image for the app
├── hello_world                 # Go binary (customized)
├── Jenkinsfile                 # Jenkins pipeline definition
├── verify_health.sh            # Health check script
├── README.md                   # Project documentation
└── terraform/
    ├── main.tf                 # Calls modules and global resources
    ├── variables.tf            # Global variables
    ├── outputs.tf              # Global outputs
    ├── providers.tf            # AWS provider + default_tags
    ├── locals.tf               # Locals and default tags
    ├── acm.tf                  # ACM certificates
    ├── cloudwatch.tf           # CloudWatch alarms and logs
    ├── cost_alarm.tf           # Cost alarm
    ├── ecr.tf                  # ECR repositories
    ├── ecs_clusters.tf         # ECS clusters and EC2 ASGs
    ├── efs.tf                  # EFS resources
    ├── iam.tf                  # Global IAM roles/policies
    ├── route53.tf              # Global DNS
    ├── s3.tf                   # Global S3 buckets
    ├── security_groups.tf      # Security Groups for ALB/ECS/EFS
    ├── sns.tf                  # Global SNS topics
    ├── waf.tf                  # WAF for geo restriction
    ├── vpc_peering.tf          # VPC peering and routes
    ├── modules/
    │   └── ecs_service/        # Reusable ECS+ALB module
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── vpc_app/                # App VPC infrastructure
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── vpc_jenkins/            # Jenkins VPC infrastructure
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

### Rationale

- **Clarity:** Resources are grouped by domain and VPC for easy navigation.
- **Reusability:** The ECS module is used for both the app and Jenkins, reducing duplication.
- **Reviewability:** Each part is isolated, making peer review straightforward.
- **Scalability:** Easy to add new services or environments.
- **Challenge Alignment:** Allows clear commenting for each resource and flaw.

### Variables

- Use object types with defaults for tags and other shared settings.
- Example:
  ```hcl
  variable "tags" {
    type = object({
      environment = optional(string, "develop")
      product     = optional(string, "cloud")
      service     = optional(string, "pipeline")
    })
  }
  ```

### Provider

- AWS provider must be configured with `default_tags` using the above tags.

---

## Usage Instructions

### Prerequisites

- AWS credentials configured
- Terraform >= 1.3.0
- Pre-commit installed (`.pre-commit-config.yaml`)

### Variables to Provide

- `domain_name`: public domain for Route53
- `email`: group email for SNS notifications
- `account-id`: AWS account ID for IAM policies

### Deploy

```sh
terraform init
pre-commit run --all-files
terraform plan -out tfplan
terraform apply tfplan
```

### Verify pre-commit validations

When going through the pre-commit validations I had to make some adjustments, and I also skipped some warnings that I thought were not necessary for this application.

```sh
Detect secrets...........................................................Passed
trim trailing whitespace.................................................Passed
fix end of files.........................................................Passed
check yaml...............................................................Passed
check for added large files..............................................Passed
detect private key.......................................................Passed
Terraform fmt............................................................Passed
Terraform validate.......................................................Passed
Terraform validate with tflint...........................................Passed
Checkov..................................................................Passed
```

### Destroy

```sh
terraform destroy
```

### AI Review

As suggested, I tried to use AI to do almost everything, I had to make some changes, but for many changes I used AI, I used Copilot chat + GPT-4.1 in the IDE, so my files served as context, facilitating usability.

### Jenkins Pipeline

The Jenkinsfile was designed to be executed on an agent with all the necessary dependencies, such as docker, aws cli, jq.

In this part I confess that I was undecided about what to do. My idea was to do everything via code build and code deploy, but I believed that it was not necessary, so I followed as requested.

One thing I did was to put an EFS in Jenkins to persist the data.

## Intentional Flaws

- **Terraform:** Over-allocated CPU in ECS Task of the application
  ```hcl
  // FLAW: ECS task CPU over-allocated, wastes resources
  cpu = 1024
  ```
- **Pipeline:** Excessive logging to S3
  ```groovy
  // FLAW: Excessive S3 logging inflates costs
  sh 'docker images | tee >(aws s3 cp - s3://${S3_BUCKET}/pipeline-${BUILD_NUMBER}.txt)'
  ```
- **Script:** Redundant health check

  ```bash
    # FLAW: Redundant call to the same endpoint
    STATUS2=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/health")

  ```

All failures are explicitly commented out in the code.

---

## Design Decision

Design decisions prioritize cost (use of free tier, minimal ASG), security (geo IP restriction, restrictive SGs, WAF), and modularity (reusable modules, global tagging). The order in which resources are created ensures that dependencies are respected and facilitates troubleshooting.

---

## Custom Docker Image: infrastructureascode/hello-world

This project uses a custom Docker image based on [`infrastructureascode/hello-world`](https://github.com/infrastructure-as-code/docker-hello-world), originally written in Go.

### Customization Steps

- The original repository was cloned locally.
- The Go source code was edited to change the output message to:

  `Hello, World MiniClip!`

- The binary was recompiled and a new Docker image was built using the following Dockerfile:

This ensures the application responds with the required custom message when deployed.

## Sensitive Data and Transcrypt

The challenge recommended using Transcrypt for sensitive credentials. In this project, no real secrets or sensitive data were included in the repository—only placeholders such as `<your-account-id>` and `<sns-topic-arn>`. Therefore, Transcrypt was not required. If any real secrets needed to be versioned, Transcrypt would have been used to ensure security and compliance.
