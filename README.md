## Deploy secure, low-latency static website with DNSSEC for Amazon Route 53 + CloudFront + WAF + Encryption(SSL/TLS) using Terraform

This Terraform project creates a production-ready AWS CloudFront distribution using modern AWS practices including
Origin Access Control (OAC), cache policies, and modular architecture.

This repository demonstrates how to deploy a secure static website on AWS using Terraform with Amazon S3, CloudFront,
Route 53, AWS Certificate Manager (ACM), AWS Web Application Firewall (WAF) and AWS KMS. The solution implements a
three-stage deployment architecture that separates DNS management, infrastructure provisioning, and content deployment
for better maintainability and security.

The infrastructure leverages enterprise-grade security features including private S3 buckets with Origin Access Control,
end-to-end encryption with customer-managed KMS keys, DNSSEC for DNS integrity, and automated HTTPS enforcement. The
deployment process is fully automated through GitHub Actions workflows with OIDC authentication, eliminating the need
for long-lived credentials.

### Architecture Overview

***

![static website architecture.jpg](static%20website%20architecture.jpg)

The project uses the following AWS services:

- CloudFront Distribution with custom domain and SSL using modular approach
- Amazon S3 — Two private buckets: one for website content, one for error pages and CloudFront access logs
- Modern Security: OAC (not legacy OAI), WAF with managed rules, optional Shield Advanced
- Cache Policies: Modern caching approach replacing forwarded_values
- DNS Management: Route53 hosted zone with domain records
- Amazon Route 53 — Hosted zone with A records (root + www) and DNSSEC enabled
- Amazon CloudFront — CDN distribution with Origin Access Control (OAC), HTTPS redirect, custom error pages, and access
  logging
- AWS Certificate Manager (ACM) — SSL/TLS certificate with DNS validation
- AWS KMS — Encryption keys for S3 buckets, SSM parameters, and DNSSEC signing
- Monitoring: CloudWatch dashboard and comprehensive alarms

### Key Modern Features

***
**Origin Access Control (OAC)**

- Replaces legacy Origin Access Identity (OAI)
- Enhanced security with AWS Signature Version 4 (SigV4)
- Support for S3 server-side encryption with AWS KMS
- Better integration with AWS services

**Cache Policies**

- Modern approach replacing forwarded_values
- Better performance and granular control
- Separate policies for different content types
- Built-in compression and encoding support

**Enterprise-Grade Security**

- Private S3 buckets with Origin Access Control (OAC) and SigV4 signing
- End-to-end encryption: KMS keys for S3 and DNSSEC signing
- TLS 1.2 minimum with automatic HTTPS redirect
- DNSSEC-enabled Route 53 hosted zone for DNS integrity
- OIDC authentication for GitHub Actions (no long-lived credentials)
- Origin Access Control (OAC): Modern secure S3 access
- WAF Protection: Blocks common attacks and implements rate limiting
- SSL/TLS: Custom domain with ACM certificate
- Security Headers: HSTS, CSP, X-Frame-Options via response headers policy
- Shield Standard: Built-in DDoS protection
- Shield Advanced: Optional premium protection

**Production-Ready Features**

- Global content delivery via CloudFront CDN
- Custom error pages (404/500) with dedicated S3 bucket
- CloudFront and S3 access logging for audit trails
- Automated cache invalidation on content updates
- S3 versioning with 90-day retention for rollback capability

**Cost & Compliance**

- Infracost integration for infrastructure cost estimation
- Checkov security scanning in CI/CD pipeline
- Automated deployment reduces manual errors and operational overhead

**Modular Architecture**

- Reusable Terraform module
- Clean separation of concerns
- Easy to maintain and extend
- Production-ready structure

### IMPORTANT: Prerequisites

***
You MUST register your domain through Route 53 FIRST before running Terraform.

- Domain registration automatically creates the hosted zone
- DNS propagation is required for SSL certificate validation
- Certificate validation will fail if domain isn't globally resolvable

Required:

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Domain registered through Route 53 (creates hosted zone automatically)

### Required AWS Permissions

***
Your AWS user/role needs permissions for:

- A registered domain with access to change its nameservers at your domain registrar
- Ensure the IAM role has permissions to create and manage all resources including Route 53, S3, CloudFront, ACM, KMS,
  WAF and CloudWatch
- For this code to function without errors, create an OpenID Connect identity provider in Amazon Identity and Access
  Management that has a trust relationship with this GitHub repository.
- Store the ARN of the IAM Role as a GitHub secret named ```AWS_ROLE_ARN``` which is referenced in the workflow files.
- For Infracost integration in this repository, the ```INFRACOST_API_KEY``` needs to be stored as a repository secret.
  It is referenced in the deploy-infrastructure.yml GitHub Actions workflow file.
- An S3 bucket for Terraform remote state — update the bucket value in ```module/bootstrap``` and ```backend.tf```

### Monitoring

***
The project includes:

- CloudWatch Dashboard: Performance metrics and error rates
- CloudWatch Alarms:
    - High 4xx error rate (>5%)
    - High 5xx error rate (>1%)
    - Low cache hit rate (<80%)
    - High origin latency (>3 seconds)
- Access Logs: Detailed request logs stored in S3

### Implementation

***
**Step 1: Project Structure**

```
s3-static-website/
├── Documentation                   # Documentation of this project and AWS services study note
├── error-pages                     # HTML file for custom error page
└── modules/
    └── acm/                        # This module sets up an ACM for certificate
          ├── main.tf
          ├── outputs.tf
          └── variables.tf
    └── bootstrap/                  # This module sets up a backend for Terraform state file
          ├── main.tf
          ├── outputs.tf
          └── variables.tf
    └── cloudfront/                 # This module creates a CloudFront for CDN
          ├── main.tf
          ├── outputs.tf
          └── variables.tf
    └── cloudwatch/                 # This module creates a monitoring for CloudFront
          ├── main.tf               
          ├── outputs.tf          
          └── variables.tf         
    └── iam/                        # This module creates an IAM for this project
          ├── ga-oidc.tf            # This code sets up IAM role Terraform execution ARN for GitHub Actions CI/CD using OIDC (OpenID Connect)
          ├── outputs.tf
          └── variables.tf
    └── kms/                        # This module sets up a KMS encryption for S3 bucket
          ├── main.tf
          ├── outputs.tf
          └── variables.tf
    └── route53/                    # This module sets up an Amazon Route 53 for DNS and DNSSEC signing
          ├── main.tf
          ├── outputs.tf
          └── variables.tf
    └── s3/                         # This module sets up a private S3 for HTML files and custom error pages + log
          ├── outputs.tf
          ├── s3-logging.tf
          ├── s3-website.tf
          └── variables.tf
    └── sns/                        # This module sets up an SNS notification system for alert
          ├── main.tf
          ├── outputs.tf
          └── variables.tf
    └── waf/                        # This module sets up a AWS WAF
          ├── main.tf
          ├── outputs.tf
          └── variables.tf
   ├── Screenshot verification      # Screenshot verification after success deployement
   ├── webfiles                     # Static HTML Files
   ├── .gitignore                   # gitignore
   ├── backend.tf                   # Backend configuration for Terraform state file
   ├── data.tf                      # Data sources
   ├── locals.tf                    # locals for common_tags
   ├── main.tf                      # Main infrastructure resources
   ├── outputs.tf                   # Output values
   ├── dev-terraform.tfvars         # The terraform.tfvars file for dev
   ├── staging-terraform.tfvars     # The terraform.tfvars file for staging
   ├── prod-terraform.tfvars        # The terraform.tfvars file for prod
   ├── providers.tf                 # Terraform and AWS provider configuration
   ├── variables.tf                 # Input variables and defaults
   ├── .github/workflows/
      ├── website-deployment.yml    # Static Website deployment workflows
      ├── terraform-checkov.yml     # Checkov workflows
```

**Step 2: Modules implementation**

- Module "bootstrap"
- Module "iam"
- Module "route53"
- Module "acm"
- Module "kms"
- Module "s3"
- Module "cloudfront"
- Module "waf"
- Upload HTML files to S3 bucket
- Upload error pages
- Module "cloudwatch"
- Module "sns"

**Step 3: Outputs**<br>
After deployment, you'll get:

- Website URLs (https://cloudwithdarvin.com)
- Website URLs (https://www.cloudwithdarvin.com)

![0-Outputs.png](Screenshot%20verification/0-Outputs.png)

**Step 4: Deployment Workflow**

- ```terraform-checkov.yml``` — Automated security scanning framework using Checkov to detect Terraform
  misconfigurations at both repository and pull request (PR) levels.
- ```deploy-infrastructure.yml``` — Terraform workflow to provision infrastructure and deploy Static Website with OIDC,
  synchronize Website content if something changed and invalidates a CloudFront cache, forcing edge servers to fetch
  fresh content from the origin.

### Quick Start

***

- **Step 1 — Fork and clone**
    - $ git clone https://github.com/darvin-rakotomalala/s3-static-website
    - $ cd s3-static-website

- **Step 2 — Configure Terraform**<br>
  Edit ```s3-static-website/dev-terraform.tfvars``` to match your target region and preferences. No secrets go here —
  just region, domain name, and default tags.

- **Step 3 — Deploy infrastructure**

  ```
  $ cd s3-static-website
  $ terraform init
  $ terraform fmt -recursive
  $ terraform validate
  $ terraform plan -var-file="dev-terraform.tfvars" -no-color -out=TFplan.JSON
  $ terraform apply -var-file="dev-terraform.tfvars" -auto-approve
  ```

### Verification

***
You can check the full documentation in ```Documentation``` directory and all screenshot in
```Screenshot verification```.

- After deploying all three steps, the site was live at https://cloudwithdarvin.com/ with a secure connection confirmed
  by the browser.

![1-Website 1.png](Screenshot%20verification/1-Website%201.png)

![1-Website 2.png](Screenshot%20verification/1-Website%202.png)

![1-Error page not found.png](Screenshot%20verification/1-Error%20page%20not%20found.png)

- On the AWS console, the CloudFront distribution showed the alternate domain names (```cloudwithdarvin.com``` and
  ```www.cloudwithdarvin.com```), the attached ACM certificate, the TLSv1.2_2021 security policy, and standard logging
  enabled.

![6-cf-distribution detail.png](Screenshot%20verification/6-cf-distribution%20detail.png)

- The two S3 origins — one for website content and one for the ops bucket — were configured correctly.

![6-cf-distribution origins.png](Screenshot%20verification/6-cf-distribution%20origins.png)

- The custom error responses are in place — HTTP 403 and 404 errors serve the custom 404 page, while 500 errors serve
  the 500 page, both from the ops bucket’s /error-pages/ prefix.

![6-cf-distribution error pages.png](Screenshot%20verification/6-cf-distribution%20error%20pages.png)

- The Route 53 hosted zone shows the A records (```root``` and ```www```) aliased to CloudFront, the NS and SOA records, and the
  CNAME records created during ACM DNS validation.

![2-Route 53.png](Screenshot%20verification/2-Route%2053.png)

- DNSSEC signing

![2-Route DNSSEC Key.png](Screenshot%20verification/2-Route%20DNSSEC%20Key.png)

### Cleanup

***
To destroy all resources, run ```terraform destroy -var-file="dev-terraform.tfvars" -auto-approve```

## License

***
This project is provided as-is for educational and production use.
