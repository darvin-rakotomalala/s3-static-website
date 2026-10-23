# Secure, Low-Latency Static Website on AWS with Terraform

Production-ready static website hosting on **Amazon S3 + CloudFront**, with **Route 53 (DNSSEC)**, **AWS WAF**, **ACM (
TLS)** and **KMS encryption**, fully provisioned with Terraform and deployed through **GitHub Actions using OIDC** (no
long-lived credentials).

![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.0-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-CloudFront%20%7C%20S3%20%7C%20Route%2053-FF9900?logo=amazonaws&logoColor=white)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)
![Security](https://img.shields.io/badge/Security-Checkov-green)

**Live example:** <https://cloudwithdarvin.com> · <https://www.cloudwithdarvin.com>

---

## Overview

### The problem

Organizations need a globally accessible, high-performance static website (marketing site, documentation portal, landing
page) with high availability and low latency worldwide, without the overhead of managing web servers. At the same time,
they must protect their brand, prevent unauthorized data access, defend against web threats and meet modern security
standards, while keeping costs low and operations automated.

### Challenges addressed

| Challenge         | Risk                                                                                                 | How this project addresses it                                                                     |
|-------------------|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| **Security**      | Publicly exposed S3 buckets, DNS spoofing and MitM attacks, DDoS, rate abuse and common web exploits | Private buckets behind OAC, DNSSEC, WAF managed rules and rate limiting, TLS 1.2+, KMS encryption |
| **Performance**   | High latency from a single storage region; poor caching                                              | Global CloudFront edge delivery, tuned cache policies, automated invalidation                     |
| **Operations**    | Long-lived IAM keys in CI/CD; configuration drift and manual errors                                  | GitHub OIDC (keyless), Terraform modules, remote state, automated pipelines                       |
| **Observability** | Origin failures or elevated 4xx/5xx errors detected too late                                         | CloudWatch dashboard, alarms and SNS notifications, access logs                                   |

---

## Architecture

![Static website architecture](static%20website%20architecture.png)

**Request flow:** Users → Route 53 (DNSSEC-signed alias record) → CloudFront (protected by WAF, TLS from ACM) → private
S3 website bucket via Origin Access Control. Error pages are served from a second private S3 bucket that also stores
access logs. Both buckets are encrypted with KMS. CloudWatch monitors the distribution.

| Service                     | Role                                                                                                                 |
|-----------------------------|----------------------------------------------------------------------------------------------------------------------|
| **Amazon Route 53**         | Hosted zone with A records (root and `www`) aliased to CloudFront; DNSSEC enabled                                    |
| **Amazon CloudFront**       | CDN with custom domain, OAC, HTTPS redirect, custom error pages, cache and response-headers policies, access logging |
| **Amazon S3**               | Two private buckets: website content, and error pages plus CloudFront access logs                                    |
| **AWS Certificate Manager** | SSL/TLS certificate with DNS validation                                                                              |
| **AWS WAF**                 | Web ACL with managed rules and rate limiting (Shield Standard included; Shield Advanced optional)                    |
| **AWS KMS**                 | Customer-managed keys for S3 buckets, SSM parameters and DNSSEC signing                                              |
| **Amazon CloudWatch / SNS** | Dashboard, alarms and alert notifications                                                                            |
| **IAM (GitHub OIDC)**       | Keyless authentication for GitHub Actions                                                                            |

---

## Features

### Security

- **Origin Access Control (OAC)** with SigV4 signing replaces legacy OAI, and supports SSE-KMS. S3 buckets stay fully
  private.
- **Encryption**: customer-managed KMS keys for S3 and DNSSEC signing; TLS 1.2 minimum (`TLSv1.2_2021`) with automatic
  HTTPS redirect.
- **DNSSEC** on the Route 53 hosted zone to guarantee DNS integrity.
- **WAF** blocks common attacks and applies rate limiting; **Shield Standard** provides built-in DDoS protection.
- **Security headers** (HSTS, CSP, X-Frame-Options) via a CloudFront response headers policy.
- **Keyless CI/CD**: GitHub Actions authenticates through OIDC.

### Performance and reliability

- Global delivery through the CloudFront edge network.
- Modern **cache policies** (replacing `forwarded_values`) with separate policies per content type and built-in
  compression.
- Custom 404/500 error pages served from a dedicated bucket.
- Automated cache invalidation on content updates.
- S3 versioning with 90-day retention for rollback.

### Operations and governance

- **Modular Terraform**: reusable modules with clear separation of concerns, one set of `.tfvars` per environment (dev,
  staging, prod).
- **Remote state** in S3, created by a one-time bootstrap module.
- **Checkov** security scanning and **Infracost** cost estimation in the pipeline.
- CloudFront and S3 access logs for audit trails.

---

## Prerequisites

> **Important:** register your domain through **Route 53 first**, before running Terraform. Registration automatically
> creates the hosted zone, and ACM certificate validation fails if the domain is not globally resolvable. If the domain
> is
> registered elsewhere, point its nameservers to the Route 53 hosted zone.

**Tools**

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with appropriate
  credentials

**AWS permissions**

The IAM identity running Terraform must be able to create and manage Route 53, S3, CloudFront, ACM, KMS, WAF,
CloudWatch, SNS and IAM resources.

**Remote state**

Provide an S3 bucket for Terraform state. Update the bucket name in `modules/bootstrap` and `backend.tf`.

**GitHub Actions (for CI/CD)**

1. Create an **OpenID Connect identity provider** in AWS IAM with a trust relationship to this GitHub repository (the
   `iam` module can provision it).
2. Add the following **repository secrets**:

| Secret              | Purpose                                                |
|---------------------|--------------------------------------------------------|
| `AWS_ROLE_ARN`      | ARN of the IAM role assumed by the workflows via OIDC  |
| `INFRACOST_API_KEY` | API key for cost estimation in the deployment workflow |

---

## Quick Start

**1. Clone the repository**

```bash
git clone https://github.com/darvin-rakotomalala/s3-static-website
cd s3-static-website
```

**2. Configure variables**

Edit `dev-terraform.tfvars` (or the staging/prod equivalent) with your region, domain name and default tags. Do not put
secrets in this file.

**3. Deploy**

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan  -var-file="dev-terraform.tfvars" -out=tfplan
terraform apply tfplan
```

**4. Outputs**

After a successful deployment Terraform prints the website URLs (`https://<your-domain>` and
`https://www.<your-domain>`).

![Terraform outputs](Screenshot%20verification/0-Outputs.png)

---

## Project Structure

```
s3-static-website/
├── .github/workflows/
│   ├── website-deployment.yml    # Infrastructure + content deployment (OIDC)
│   └── terraform-checkov.yml     # Checkov security scanning
├── Documentation/                # Project documentation and AWS study notes
├── Screenshot verification/      # Post-deployment verification screenshots
├── error-pages/                  # Custom 404 / 500 HTML pages
├── webfiles/                     # Static website content (HTML, CSS, JS)
├── modules/
│   ├── acm/                      # SSL/TLS certificate with DNS validation
│   ├── bootstrap/                # Remote state backend (run once)
│   ├── cloudfront/               # CDN distribution
│   ├── cloudwatch/               # Dashboard and alarms
│   ├── iam/                      # GitHub Actions OIDC role (ga-oidc.tf)
│   ├── kms/                      # Encryption keys
│   ├── route53/                  # Hosted zone, records and DNSSEC
│   ├── s3/                       # Website and logging buckets
│   │                             #   (s3-website.tf, s3-logging.tf)
│   ├── sns/                      # Alert notifications
│   └── waf/                      # Web ACL
├── backend.tf                    # Remote state configuration
├── data.tf                       # Data sources
├── locals.tf                     # Common tags
├── main.tf                       # Root module wiring
├── outputs.tf                    # Output values
├── providers.tf                  # Terraform and AWS provider configuration
├── variables.tf                  # Input variables and defaults
├── dev-terraform.tfvars          # Environment: dev
├── staging-terraform.tfvars      # Environment: staging
└── prod-terraform.tfvars         # Environment: prod
```

Each module contains `main.tf`, `outputs.tf` and `variables.tf` unless noted above.

---

## Terraform Modules

| Module       | Responsibility                                                                                                                                                                 |
|--------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `bootstrap`  | Creates the S3 remote state backend for Terraform itself. Run once before enabling remote state.                                                                               |
| `iam`        | Configures keyless GitHub Actions to AWS authentication via OIDC. No long-lived credentials stored in GitHub.                                                                  |
| `route53`    | DNS hosting for the domain and DNSSEC signing.                                                                                                                                 |
| `acm`        | Requests the SSL/TLS certificate and validates it through Route 53 DNS records.                                                                                                |
| `kms`        | KMS keys that encrypt the S3 buckets (and DNSSEC signing).                                                                                                                     |
| `s3`         | Private S3 buckets for website content, custom error pages and logs, with versioning and encryption. Content and error pages are uploaded from `webfiles/` and `error-pages/`. |
| `cloudfront` | CDN distribution: OAC, cache and response-headers policies, custom domain, error responses and logging.                                                                        |
| `waf`        | Web ACL with managed rules and rate limiting, attached to CloudFront.                                                                                                          |
| `cloudwatch` | Dashboard and alarms for the distribution.                                                                                                                                     |
| `sns`        | Notification topic for CloudFront alerts.                                                                                                                                      |

---

## CI/CD Workflows

| Workflow                 | Purpose                                                                                                                                                                                                                |
|--------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `terraform-checkov.yml`  | Scans Terraform for misconfigurations with Checkov on the repository and on pull requests.                                                                                                                             |
| `website-deployment.yml` | Authenticates with OIDC, provisions infrastructure with Terraform (including Infracost estimation), syncs website content when it changes, and invalidates the CloudFront cache so edge locations fetch fresh content. |

---

## Monitoring

- **CloudWatch dashboard**: performance metrics and error rates.
- **CloudWatch alarms** (notifications sent through SNS):

| Alarm               | Threshold   |
|---------------------|-------------|
| High 4xx error rate | > 5%        |
| High 5xx error rate | > 1%        |
| Low cache hit rate  | < 80%       |
| High origin latency | > 3 seconds |

- **Access logs**: detailed CloudFront request logs stored in the logging S3 bucket.

---

## Verification

Full documentation is in `Documentation/` and all screenshots are in `Screenshot verification/`.

**Website**: after deployment the site is live over HTTPS, with the secure connection confirmed by the browser, and
unknown paths serve the custom error page.

![Website home](Screenshot%20verification/1-Website%201.png)
![Website content](Screenshot%20verification/1-Website%202.png)
![Custom error page](Screenshot%20verification/1-Error%20page%20not%20found.png)

**CloudFront**: the distribution shows the alternate domain names (`cloudwithdarvin.com`, `www.cloudwithdarvin.com`),
the attached ACM certificate, the `TLSv1.2_2021` security policy and standard logging enabled.

![CloudFront distribution](Screenshot%20verification/6-cf-distribution%20detail.png)

**Origins**: two S3 origins are configured, one for website content and one for the operations bucket.

![CloudFront origins](Screenshot%20verification/6-cf-distribution%20origins.png)

**Custom error responses**: HTTP 403 and 404 serve the custom 404 page and HTTP 500 serves the 500 page, both from the
`/error-pages/` prefix of the operations bucket.

![CloudFront error pages](Screenshot%20verification/6-cf-distribution%20error%20pages.png)

**Route 53**: A records (root and `www`) are aliased to CloudFront, alongside the NS and SOA records and the CNAME
records created for ACM DNS validation.

![Route 53 records](Screenshot%20verification/2-Route%2053.png)

**DNSSEC**: signing is enabled on the hosted zone.

![DNSSEC key](Screenshot%20verification/2-Route%20DNSSEC%20Key.png)

---

## Cleanup

To destroy all resources:

```bash
terraform destroy -var-file="dev-terraform.tfvars"
```

> Review the destroy plan before confirming. Versioned S3 buckets may need to be emptied first.

---

## License

This project is provided as-is for educational and production use.
