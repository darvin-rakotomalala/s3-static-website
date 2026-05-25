## Deploy secure, low-latency static website with DNSSEC for Amazon Route 53 + CloudFront + WAF + Encryption (SSL/TLS) using Terraform

---

## Table of Contents

- [Project Overview](#project-overview)
- [The Challenge](#the-challenge)
- [Solution Overview](#solution-overview)
- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [Traffic Flow](#traffic-flow)
- [Key Features](#key-features)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
    - [Required AWS Permissions](#required-aws-permissions)
    - [Project Structure](#project-structure)
    - [Required GitHub Secrets](#required-github-secrets)
- [Step 1 – Remote State Backend & OIDC CI/CD Authentication](#step-1--remote-state-backend-infrastructure-and-github-actions-cicd-authentication-using-oidc)
- [Step 2 – Provision the Route 53 Hosted Zone](#step-2-provision-the-route-53-hosted-zone)
- [Step 3 – Deploy S3 Buckets, CloudFront Distribution & SSL Certificate](#step-3-deploy-s3-buckets-cloudfront-distribution-and-ssl-certificate)
- [Step 4 – Deploy Content and Invalidate Cache](#step-4-deploy-content-and-invalidate-cache)
- [Monitoring](#monitoring)
- [Quick Start](#quick-start)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Conclusion](#conclusion)

---

## Project Overview

This Terraform project demonstrates how to deploy a secure static website on AWS using Terraform with Amazon S3,
CloudFront, Route 53, AWS Certificate Manager (ACM), AWS KMS, and AWS WAF.

AWS offers flexible pricing options of Content Delivery Network (CDN) with CloudFront, providing easy deployment options
to start. If you are accessing any enterprise-level website or watching videos, you are accessing content from a CDN.
CDN can not only help by adding caching, but also provides options to increase security, improve high availability, and
save bandwidth on your origin servers. This is where Amazon CloudFront becomes your secret weapon — it's not just
another AWS service; it's the difference between a sluggish website and a lightning-fast user experience that keeps
customers coming back.

---

## The Challenge

**Hosting static websites** on traditional servers requires managing OS patches, web server configuration, SSL renewal,
and scaling — tasks that add no value for static content. **Amazon S3**, **CloudFront**, and **Route 53** remove this
overhead while providing global CDN distribution, managed SSL, and DNS.

---

## Solution Overview

This Terraform project demonstrates production-ready AWS CloudFront distribution using modern AWS practices. The
solution implements a three-steps deployment architecture that DNS management, infrastructure provisioning,
and content deployment for better maintainability and security.

In this project:

- **Amazon S3** is used to **store** website files
- **Amazon CloudFront** is used to **cache** and **serve** them globally over HTTPS
- **Amazon Route 53** is used to **route** the custom domain to CloudFront

Together, they form a complete static hosting platform. The setup also includes **ACM** for SSL certificates, **AWS KMS
** encryption for storage, **AWS WAF** to protect against attacks, and **DNSSEC** for DNS security.

---

## Architecture Overview

This solution consists of three dependent steps:

- **Step 1** provisions the Route 53 hosted zone and enables DNSSEC.
- **Step 2** deploys the S3 buckets, CloudFront distribution, SSL certificate, and enables WAF to protect against
  attacks — using the hosted zone from **Step 1** for DNS validation.
- **Step 3** handles content deployment, updating website content without re-provisioning infrastructure, and
  relies on the infrastructure built in Step 2.

![static website architecture.jpg](../static%20website%20architecture.jpg)

---

## Tech Stack

The solution uses the following AWS services:

| Service                           | Description                                                                                               |
|-----------------------------------|-----------------------------------------------------------------------------------------------------------|
| **Amazon Route 53**               | Hosted zone with A records (root + www) and DNSSEC enabled                                                |
| **Amazon CloudFront**             | CDN distribution with Origin Access Control (OAC), HTTPS redirect, custom error pages, and access logging |
| **Amazon S3**                     | Two private buckets: one for website content, one for error pages and CloudFront access logs              |
| **AWS Certificate Manager (ACM)** | SSL/TLS certificate with DNS validation                                                                   |
| **AWS KMS**                       | Encryption keys for S3 buckets, SSM parameters, and DNSSEC signing                                        |
| **AWS WAF**                       | Enable WAF to protect against attacks                                                                     |

---

## Traffic Flow

This diagram shows a secure, scalable static website hosting setup on AWS. Here's how it flows:

1. User → Route53 → CloudFront (HTTPS / TLS 1.2/1.3)
2. CloudFront → WAF → S3 (HTTPS/TLS 1.2/1.3)
3. Response → S3 → CloudFront → User

### Request Flow (Steps 1 → 2 → 3)

- **Step 1 — DNS Resolution (Users → Route 53):** Users type a URL in their browser. Amazon Route 53 handles DNS
  resolution via an **A record (DNS alias)**. Route 53 also uses **AWS KMS** to manage a **DNSSEC signing key**,
  protecting against DNS spoofing attacks.

- **Step 2 — Content Delivery (Route 53 → CloudFront):** Traffic is routed to **Amazon CloudFront** (the CDN), which:

    - Uses an **SSL/TLS certificate** from AWS Certificate Manager (ACM) for HTTPS
    - Is monitored by **Amazon CloudWatch** for metrics and alarms
    - Is protected by **AWS WAF** (Web Application Firewall) via a **Web ACL**, filtering malicious traffic
    - Sends error pages and access logs to a dedicated **Amazon S3 bucket** (also KMS-encrypted)
- **Step 3 — Content Storage (CloudFront → S3):** CloudFront fetches static files from a **primary Amazon S3 bucket** (
  the Website Bucket). The static HTML files are uploaded here by developers/CI pipelines. This bucket is also *
  *encrypted using AWS KMS**.

### Key Security Layers

| Layer              | Service        | Purpose                  |
|--------------------|----------------|--------------------------|
| DNS Security       | KMS + Route 53 | DNSSEC protection        |
| Transport          | ACM            | HTTPS/TLS certificates   |
| Edge Protection    | AWS WAF        | Block malicious requests |
| Storage Encryption | AWS KMS        | Encrypt both S3 buckets  |
| Observability      | CloudWatch     | Monitor & alert          |

### SSL/TLS for Data in Transit

- HTTPS (TLS 1.2/1.3) between User ↔ CloudFront
- TLS 1.2/1.3 between CloudFront ↔ S3

### Amazon CloudFront (CDN)

- Global Edge Locations
- Caching (Images, CSS, JS, Articles)
- DDoS Protection (Edge)
- HTTPS (TLS 1.2/1.3)

### AWS WAF (Web Application Firewall)

- OWASP Top 10 Protection
- SQL Injection Protection
- XSS Protection
- IP Rate Limiting
- Geo Blocking
- Bot Control

### Amazon S3 (Encrypted)

- SSE-S3 / SSE-KMS (AES-256)
- Encryption Keys managed by AWS KMS

### AWS Certificate Manager (ACM)

- SSL/TLS Certificates from AWS Certificate Manager (ACM)
- Used by CloudFront
- Enforces HTTPS (443)
- Supports TLS 1.2 and TLS 1.3

### Security Highlights

- Only HTTPS (443) allowed
- WAF protects from common attacks
- All data in transit encrypted (TLS)
- All data at rest encrypted
- Least privilege access
- Centralized key management (KMS)

### Monitoring & Supporting Services

- Amazon CloudWatch (Monitoring & Logs)
- AWS CloudTrail (Audit Logs)

### Key Management — AWS KMS (Keys Encrypted & Rotated)

This is a well-architected, **serverless** static hosting pattern — no EC2 instances needed, highly available by
default, and secure end-to-end.

---

## Key Features

### Three-Stage Deployment Architecture

- Isolated DNS, infrastructure, and content deployment workflows
- Deploys the S3 buckets, CloudFront distribution, SSL certificate, and WAF
- Independent state management for each deployment layer

### Enterprise-Grade Security

- Private S3 buckets with Origin Access Control (OAC) and SigV4 signing
- End-to-end encryption: KMS keys for S3, SSM parameters, and DNSSEC signing
- TLS 1.2 minimum with automatic HTTPS redirect
- DNSSEC-enabled Route 53 hosted zone for DNS integrity
- OIDC authentication for GitHub Actions (no long-lived credentials)
- AWS Web Application Firewall (WAF) to protect against attacks

### Production-Ready Features

- Global content delivery via CloudFront CDN
- Custom error pages (404/500) with dedicated S3 bucket
- CloudFront and S3 access logging for audit trails
- Automated cache invalidation on content updates
- S3 versioning with 90-day retention for rollback capability
- AWS WAF to filter malicious requests and provide protection from intruders
- Monitoring via AWS CloudWatch service to create dashboards and alarms in case of errors and performance issues

### Cost & Compliance

- **Infracost** integration for infrastructure cost estimation
- **Checkov** security scanning in CI/CD pipeline
- Automated deployment reduces manual errors and operational overhead
- To improve performance, enable compression and also enable it for images in the terraform module. Optimize cache key
  by including only required headers, cookies, and query strings.
- For cost optimization, select the correct price class. Allow only geographic regions where you want to allow users to
  access the application. Use different TTL for static and dynamic content. Use primary and secondary origins to
  increase availability. Use cache invalidation carefully.

### Modular Architecture

- Reusable Terraform modules
- Clean separation of concerns
- Easy to maintain and extend
- Production-ready structure

---

## Prerequisites

- An AWS account with an IAM role configured for GitHub Actions via OIDC. This eliminates long-lived credentials.
- An Amazon S3 bucket for Terraform remote state.
- **Register domain through Route 53:** This is a pre-requisite before running Terraform code. You can buy a domain from
  an external DNS provider or buy from the Route53 DNS request option.
- You have to use your name domain as part of the Route 53 zone.

---

## Implementation

### Prerequisites

- AWS CLI v2+ configured with `aws configure` and with appropriate permissions
- Terraform \>= 1.14.8 installed
- Domain registered through Route 53 (creates hosted zone automatically)

### Required AWS Permissions

Your AWS user/role needs permissions for:

- A registered domain with access to change its nameservers at your domain registrar
- Ensure the IAM role has permissions to create and manage all resources including Route 53, S3, CloudFront, ACM, KMS,
  and WAF
- CloudWatch (dashboard and metrics access)
- For this code to function without errors, create an OpenID Connect identity provider in Amazon Identity and Access
  Management that has a trust relationship with this GitHub repository.
- Store the ARN of the IAM Role as a GitHub secret named `AWS_ROLE_ARN` which is referenced in the workflow files.
- An S3 bucket for Terraform remote state — update the bucket value in `bootstrap/` module and `backend.tf`.

### Project Structure

```
s3-static-website/
├── Documentation          # Documentation of this project and AWS services study note
├── error-pages            # HTML file for custom error page
└── modules/
    ├── acm/               # This module sets up an ACM for certificate
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── bootstrap/         # This module sets up a backend for Terraform state file
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── cloudfront/        # This module creates a CloudFront for CDN
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── cloudwatch/        # This module creates a monitoring for CloudFront
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── iam/               # This module creates an IAM for this project
    │   ├── ga-oidc.tf     # This code sets up IAM role Terraform execution ARN for CI/CD
    │   ├── outputs.tf
    │   └── variables.tf
    ├── kms/               # This module sets up a KMS encryption for S3 bucket
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── route53/           # This module sets up an Amazon Route 53 for DNS and DNSSEC signing
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── s3/                # This module sets up a private S3 for HTML files and custom error pages + log
    │   ├── outputs.tf
    │   ├── s3-logging.tf
    │   ├── s3-website.tf
    │   └── variables.tf
    ├── sns/               # This module sets up an SNS notification system for alert
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── waf/               # This module sets up an AWS WAF
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
├── Screenshot verification    # Screenshot verification after success deployment
├── webfiles                   # Static HTML Files
├── .gitignore                 # gitignore
├── backend.tf                 # Backend configuration for Terraform state file
├── data.tf                    # Data sources
├── locals.tf                  # locals for common_tags
├── main.tf                    # Main infrastructure resources
├── outputs.tf                 # Output values
├── dev-terraform.tfvars       # The terraform.tfvars file for dev
├── staging-terraform.tfvars   # The terraform.tfvars file for staging
├── prod-terraform.tfvars      # The terraform.tfvars file for prod
├── providers.tf               # Terraform and AWS provider configuration
├── variables.tf               # Input variables and defaults
└── .github/workflows/
    ├── website-deployment.yml     # Static Website deployment workflows
    ├── terraform-checkov.yml      # Checkov workflows
    └── terraform-infracost.yml    # Infracost workflows

```

### Required GitHub Secrets

Go to **Settings → Secrets and variables → Actions** in your fork:

| Secret                 | Description                  |
|------------------------|------------------------------|
| `AWS_REGION`           | `us-east-1`                  |
| `AWS_ROLE_ARN`         | Your github-actions-role ARN |
| `TF_BACKEND_S3_BUCKET` | Your state bucket name       |
| `TF_VERSION`           | `1.14.8`                     |

---

### Step 1: Remote State Backend Infrastructure and GitHub Actions CI/CD Authentication using OIDC

### Module "bootstrap"

This code sets up the **remote state backend infrastructure** for Terraform itself — it's the "bootstrap" you run once
before using remote state.

#### The Problem It Solves

By default, Terraform stores its state file locally. In a team or CI/CD environment you need that state stored remotely
and protected. This code creates that remote storage on AWS.

#### Resource by Resource

1. **`aws_s3_bucket.terraform_state`** — Creates the S3 bucket that will store your `.tfstate` files.

2. **`aws_s3_bucket_versioning.terraform_state`** — Enables **versioning** on the bucket.

    - Every time Terraform writes a new state, the old one is preserved as a previous version
    - This lets you **roll back** to any prior state if something goes wrong
3. **`aws_s3_bucket_server_side_encryption_configuration.terraform_state`** — Encrypts everything in the bucket at rest
   using **AWS KMS**.

    - State files often contain sensitive values (passwords, keys, IPs), so encryption is critical
    - `aws:kms` uses AWS-managed keys by default (you can swap in a customer-managed key)
4. **`aws_s3_bucket_public_access_block.terraform_state`** — Blocks all public access to the bucket — all four settings
   set to `true`.

    - Prevents accidental public exposure of your state file
    - Acts as a hard override even if someone tries to add a public bucket policy later
5. **`aws_dynamodb_table.terraform_locks`** — Creates a DynamoDB table for **state locking**.

    - When Terraform runs, it writes a LockID entry to this table
    - If two people (or two CI jobs) run `terraform apply` simultaneously, the second one sees the lock and waits or
      errors — preventing **state corruption**
    - `PAY_PER_REQUEST` means no capacity planning needed; you only pay per lock/unlock operation

#### How They Work Together

```
terraform apply
      │
      ▼
Reads state ◄── S3 bucket (versioned + encrypted + private)
      │
      ▼
Acquires lock ──► DynamoDB table (LockID)
      │
      ▼
Makes changes
      │
      ▼
Writes new state ──► S3 bucket
      │
      ▼
Releases lock ──► DynamoDB (deletes LockID row)

```

### Module "iam" — ga-oidc.tf

This code sets up **GitHub Actions CI/CD authentication to AWS** using OIDC (OpenID Connect) — a keyless, token-based
auth method. No long-lived AWS credentials stored in GitHub secrets.

#### Overall Flow

```
GitHub Actions job starts
      │
      ▼
GitHub issues a signed OIDC JWT token
      │
      ▼
Workflow calls sts:AssumeRoleWithWebIdentity with that token
      │
      ▼
AWS verifies the token against the registered OIDC provider
      │
      ▼
AWS checks repo/org conditions match
      │
      ▼
AWS returns short-lived credentials (max 1h)
      │
      ▼
Terraform runs with those credentials

```

---

### Step 2: Provision the Route 53 Hosted Zone

- We provisioned the Route 53 hosted zone, which became the domain's authoritative DNS zone once configured its
  nameservers at the domain registrar (SquareSpace). We also enabled DNSSEC using an AWS KMS (Key Management System) Key
  Signing Key to cryptographically protect DNS responses against tampering.

- **DNSSEC (Domain Name System Security Extensions)** is a security protocol that adds cryptographic signatures to DNS
  records. This ensures that users are connecting to legitimate websites rather than malicious ones. It also helps
  prevent attacks like DNS spoofing or cache poisoning by verifying the authenticity and integrity of DNS responses.

- **Amazon Route 53** is a scalable and highly available domain name system (DNS) web service that helps route end-user
  requests to applications hosted on AWS. It supports domain registration, DNS routing, and target health checking to
  ensure reliable application performance. Route 53 also **supports security features like DNSSEC**. Integrating Amazon
  Route 53 with DNSSEC **tightens security** to ensure the authenticity of DNS responses.

- **DNSSEC adds digital signatures to DNS records** so that when someone looks up a domain (like amazon.com), they can
  verify that the DNS info came from the right source and wasn't tampered with. In AWS, this is achieved by: **(i)**
  creating an asymmetric KMS Key for DNSSEC signing, **(ii)** enabling it for use with Amazon Route53, **(iii)**
  associating the KMS Key with the Amazon Route53 hosted zone to create a Key Signing Key, **(iv)** activating DNSSEC
  for the hosted zone, and **(v)** updating the DS records with the domain registrar to link the domain to the DNSSEC
  chain of trust.

- Here is
  a [link to a detailed guide from AWS-Docs](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec.html)
  on enabling DNSSEC signing and establishing a chain of trust.

### Module "route53"

This code sets up **DNS hosting and DNSSEC security** for a domain on AWS.

#### 1\. Route 53 Hosted Zone (`aws_route53_zone.main`)

Creates a **DNS zone** for your domain — essentially a container that holds all DNS records for `var.domain_name`.

#### 2\. KMS Key for DNSSEC (`aws_kms_key.dnssec`)

Creates a **cryptographic signing key** used to sign DNS records:

- `ECC_NIST_P256` — an elliptic curve algorithm required by Route 53 for DNSSEC
- `SIGN_VERIFY` usage — the key can only sign and verify, not encrypt data
- 7-day deletion window — a safety buffer before the key is permanently destroyed
- **Must be in us-east-1** — a hard AWS requirement for DNSSEC keys

#### 3\. KMS Alias (`aws_kms_alias.dnssec`)

Creates a **human-readable name** for the KMS key (e.g., `alias/myapp-example-com-dnssec`) so it's easier to identify in
the AWS console.

#### 4\. KMS Key Policy (`aws_kms_key_policy.dnssec`)

Defines **who can do what** with the signing key.

#### 5\. Key Signing Key (`aws_route53_key_signing_key.main`)

Links the KMS key to your hosted zone as a **Key Signing Key (KSK)** — the actual DNSSEC signing mechanism attached to
the zone. Set to **ACTIVE** so it immediately starts being used.

#### 6\. Enable DNSSEC (`aws_route53_hosted_zone_dnssec.main`)

**Turns DNSSEC on** for the hosted zone. Once applied, Route 53 will cryptographically sign all DNS responses,
protecting against DNS spoofing/cache poisoning attacks.

#### 7\. DNS Records (`aws_route53_record.root` + `.www`)

Two **A records** that point your domain to a CloudFront distribution:

- `cloudwithdarvin.com` → CloudFront (root domain)
- `www.cloudwithdarvin.com` → CloudFront (www subdomain)

Both use **alias records** (AWS-native, free, and auto-updating) rather than plain A records with hardcoded IPs.

#### 8\. Overall Architecture

```
cloudwithdarvin.com (Route 53 Zone)
      │
      ├── DNSSEC enabled (KMS key signs all responses)
      │
      ├── example.com ──alias──► CloudFront Distribution
      └── www.example.com ──alias──► CloudFront Distribution

```

---

### Step 3: Deploy S3 Buckets, CloudFront Distribution, and SSL Certificate

The second stage focuses on creating the remaining infrastructure components.

### Provision SSL Certificate (ACM + DNS Validation)

- CloudFront only accepts certificates from `us-east-1`, regardless of where your other infrastructure lives.
- CloudFront is a global service, but certificates **must be in the us-east-1 region**.
- For certificate validation, you need to add the CNAME record mentioned in ACM services to prove you own the domain:
    - **ACM generates validation records** with random values
    - **You add CNAME records** to your DNS zone
    - **ACM checks the records** to verify domain ownership
    - **Certificate becomes valid** once verification succeeds

### Module "acm"

This code provisions and validates an **SSL/TLS certificate** for a website using AWS Certificate Manager (ACM) and
Route 53. It has three resources that work together in sequence.

#### 1\. `aws_acm_certificate` — Request the Certificate

- Requests a certificate that covers **both the apex and www subdomain**
- Uses **DNS validation** (as opposed to email), meaning AWS will verify you own the domain by checking for specific DNS
  records
- `create_before_destroy` ensures a new cert is provisioned before the old one is destroyed, avoiding downtime during
  replacements
- The commented-out `provider = aws.us_east_1` is a reminder that **CloudFront requires ACM certs to live in us-east-1
  **, regardless of your default region

#### 2\. `aws_route53_record` — Create DNS Validation Records

- ACM gives back a set of `domain_validation_options` — one per domain/SAN — each containing a special DNS record AWS
  wants to see
- The `for_each` loop **iterates over both domains** and creates a Route 53 record for each
- `allow_overwrite = true` prevents errors if the record already exists
- Short `ttl = 60` helps AWS pick up the records quickly

#### 3\. `aws_acm_certificate_validation` — Wait for Validation to Complete

- This resource **doesn't create anything** — it's a Terraform gate that blocks until AWS confirms the certificate is
  validated
- It passes the FQDNs of the DNS records created above so Terraform knows what to watch
- The 10-minute timeout gives AWS enough time to propagate and verify the DNS records

#### 4\. The Overall Flow

```
Request cert (ACM)
      │
      │ returns domain_validation_options
      ▼
Create DNS records (Route 53)
      │
      │ AWS detects DNS records, validates ownership
      ▼
Wait for validation (ACM Validation)
      │
      ▼
Certificate is ISSUED ✓ → ready for CloudFront / ALB

```

### Create an AWS KMS Key for S3 Encryption

- This setup uses two S3 buckets — one for website content and one for operational files such as error pages and access
  logs.
- CloudFront needs the `kms:Decrypt` permission to read objects from encrypted buckets via Origin Access Control.
- The key policy also grants the S3 service access to encryption/decryption and the account root full management
  permissions.

### Module "kms"

This code sets up an **AWS KMS (Key Management Service) encryption key** for securing S3 bucket data.

#### 1\. `aws_kms_key` — Creates the KMS Key

- A **7-day deletion window** — if you delete the key, AWS waits 7 days before permanently destroying it (safety net)
- **Automatic key rotation enabled** — AWS rotates the cryptographic material yearly, a security best practice
- **Tags** merging common project tags with key-specific metadata (name, type, purpose)

#### 2\. `aws_kms_alias` — Creates a Human-Readable Alias

KMS keys have unwieldy IDs by default. This creates a friendly alias like `alias/myproject-encrypt-s3`, making it easier
to reference in other services or the AWS Console.

#### 3\. `aws_iam_policy_document` — Defines Who Can Use the Key

This data source builds a JSON policy with **three permission statements**:

- The **root account statement** is actually an AWS requirement — without it, only the key policy controls access, which
  could lock you out. It delegates key management back to IAM.
- CloudFront gets **read-only crypto permissions** (just Decrypt + DescribeKey) because it only needs to serve/read
  encrypted objects, never write them.

#### 4\. `aws_kms_key_policy` — Attaches the Policy to the Key

This final resource takes the JSON policy document built above and actually attaches it to the KMS key, making the
permissions active.

#### 5\. Big Picture

```
KMS Key ──► used by S3 to encrypt stored objects
         ──► used by CloudFront to decrypt objects for delivery
         ──► managed by your AWS account via IAM

```

### Create an S3 Website Bucket with Encryption, Versioning, and Lifecycle Policies

- The website bucket stores the static HTML files served through CloudFront.
- It uses the KMS key from the previous step for server-side encryption, blocks all public access, and enables
  versioning so you can roll back content changes.
- A lifecycle policy expires noncurrent versions after 90 days and cleans up incomplete multipart uploads.

### Module "s3" — s3-website.tf

This code provisions a **secure, production-grade S3 bucket** designed to host a static website (HTML, CSS, JS, images)
behind CloudFront.

#### `random_string.bucket_suffix`

Generates an 8-character random lowercase alphanumeric string. Since S3 bucket names must be **globally unique**,
appending this suffix to the bucket name avoids naming collisions across AWS accounts.

#### `aws_s3_bucket.website` — The Core Bucket

#### `aws_s3_bucket_logging.website` — Access Logging

Sends access logs to a **separate S3 bucket** (`cloudfront_ops` from a logging module). Logs are prefixed with
`access_logs/`, enabling auditing of who accessed or requested objects.

#### `aws_s3_bucket_server_side_encryption_configuration.website` — Encryption at Rest

Encrypts all objects using **AWS KMS** (`aws:kms`) with a customer-managed key (CMK) whose ARN comes from a KMS module.
This is stronger than the default S3-managed encryption (AES-256), giving you full control over key rotation and access
policies.

#### `aws_s3_bucket_website_configuration.website` — Static Website Hosting

Enables S3's built-in static website hosting:

- `index.html` is served for root/directory requests
- `error.html` is served for 4xx errors

> **Note**: Even though website hosting is enabled, public access is blocked. In practice, this bucket is accessed *
*exclusively through CloudFront**, not directly via the S3 website endpoint.

#### `aws_s3_bucket_public_access_block.website` — Security Hardening

Blocks **all public access** to the bucket at every level (ACLs and bucket policies).

#### `aws_s3_bucket_versioning.website` — Object Versioning

Keeps a full history of every object version:

- **Rollback** to a previous deployment if a bad file is uploaded
- Protection against accidental deletions

#### `aws_s3_bucket_lifecycle_configuration.website` — Cost Management

| Rule                                | Behavior                                                  |
|-------------------------------------|-----------------------------------------------------------|
| `noncurrent_version_expiration`     | Permanently deletes old object versions after **90 days** |
| `abort_incomplete_multipart_upload` | Cleans up failed/partial uploads after **7 days**         |

#### Overall Architecture Summary

```
CloudFront → S3 Bucket (private, encrypted, versioned)
                  ↓ logs
            S3 Logging Bucket (cloudfront_ops)

```

### Create S3 Ops Bucket for Error Pages and CloudFront Access Logs

- The ops bucket serves two purposes: it hosts custom error pages (404, 500) that CloudFront serves when errors occur,
  and it receives CloudFront access logs under the `logs/` prefix.
- Lifecycle policies transition logs to Standard-IA after 30 days, Glacier after 90 days, and delete them after one year
  to control storage costs.

### Module "s3" — s3-logging.tf

This Terraform code provisions a **single S3 bucket** designed to support CloudFront operations (logs, error pages,
etc.), with a full set of security and cost-management configurations.

#### 1\. `aws_s3_bucket` — The Bucket Itself

- Creates the S3 bucket with a **unique, randomized name** to avoid global naming conflicts.
- `force_destroy = true` means Terraform can delete the bucket **even if it contains objects** — convenient for
  teardowns, but be careful in production.

#### 2\. `aws_s3_bucket_ownership_controls` — Object Ownership

- Ensures that **your AWS account owns all objects** written to the bucket, even if uploaded by another account (like
  CloudFront's logging service).
- Required because CloudFront writes logs using a cross-account delivery mechanism that relies on ACLs.

#### 3\. `aws_s3_bucket_acl` — Access Control List

- Sets the bucket ACL to **private** (no public access via ACL).

#### 4\. `aws_s3_bucket_public_access_block` — Public Access Settings

| Setting                   | Value | Meaning                                            |
|---------------------------|-------|----------------------------------------------------|
| `block_public_acls`       | false | Allows ACLs (needed for CloudFront logging)        |
| `block_public_policy`     | true  | Blocks any bucket policy that grants public access |
| `ignore_public_acls`      | false | Honors ACLs (again, for CloudFront)                |
| `restrict_public_buckets` | true  | Prevents public access via policies                |

#### 5\. `aws_s3_bucket_versioning` — Versioning

Keeps **multiple versions of every object**, protecting against accidental deletions or overwrites. Useful for
recovering overwritten log files or error pages.

#### 6\. `aws_s3_bucket_server_side_encryption_configuration` — Encryption at Rest

All objects are **encrypted with a customer-managed KMS key**.

#### 7\. `aws_s3_bucket_lifecycle_configuration` — Cost & Hygiene Rules

**Rule 1 — `abort_incomplete_uploads`** — Automatically cancels any **stalled multipart upload** after 7 days.

**Rule 2 — `manage_log_files`** (prefix: `logs/`) — A tiered storage strategy to reduce costs as logs age:

- **Day 0–30:** Standard (fast, full-price)
- **Day 30–90:** Standard-IA (~45% cheaper)
- **Day 90–365:** Glacier (~80% cheaper)
- **After 365 days:** Deleted entirely

**Rule 3 — `manage_error_pages`** (prefix: `error-pages/`) — Error pages are kept **indefinitely** (no expiration), but
incomplete multipart uploads are still cleaned up after 7 days.

#### Big Picture

```
aws_s3_bucket ← core bucket
  ├── ownership_controls   (cross-account write support for CloudFront)
  ├── acl                  (private, but ACL-capable)
  ├── public_access_block  (surgical public access control)
  ├── versioning           (object history)
  ├── encryption           (KMS at rest)
  └── lifecycle            (cost tiering + cleanup)

```

### Create CloudFront Origin Access Controls

- Origin access control is a must-have policy to restrict origin access by CloudFront only, preventing direct access by
  users or attackers. So users must access the web application through CloudFront and origin will remain private and
  protected.
- Origin Access Control (OAC) is the mechanism that allows CloudFront to access private S3 buckets. Two OAC resources
  were created — one for the website bucket and one for the ops bucket's error pages — each using SigV4 signing to
  authenticate requests to `origin_access_control_origin_type`, which is set to `s3`.
- S3 as origin as it's easy to deploy for testing, cost effective, and highly available.

### Create CloudFront Distribution

- The distribution is the central resource that ties everything together. It defines two origins (_the backend sources
  from where CloudFront fetches content_): the website bucket for static content and the ops bucket for error pages.
- The distribution is configured with aliases for both the root domain and the www subdomain, and uses `index.html` as
  the default root object, so visitors hitting the base URL get the homepage.
- The default cache behavior routes all requests to the website bucket. It redirects HTTP visitors to HTTPS
  automatically.
- The Managed-SecurityHeadersPolicy AWS policy is also attached, which adds security headers like
  Strict-Transport-Security, X-Content-Type-Options, and X-Frame-Options to all responses.

### Cache Policies

- Cache policies in CloudFront distribution are managed from distribution cache behavior:

    - **HTML Content Policy**
    - **Static Assets Policy**
- An ordered cache behavior matches the `/error-pages/*` path pattern and routes those requests to the ops bucket — a
  separate behavior is needed because the error pages are stored in a different origin than the website content.

- Custom error responses map the HTTP 404, 403, and 500 error codes to the corresponding error pages.

- Finally, the access logging writes to the ops bucket under the `logs/` prefix, and the ACM certificate from the
  previous step enables HTTPS on the custom domain.

### Create Route 53 A Records for CloudFront

In this step, two **alias A records** were created — one for the root domain and one for `www` — to point to the
CloudFront distribution.

#### Configure the Two S3 Bucket Policies for CloudFront Access

- The bucket policies are what actually grant CloudFront permission to access the S3 buckets through OAC.
- The website bucket policy allows `s3:GetObject` for the CloudFront service principal, scoped to the distribution's
  ARN.
- The ops bucket policy has two statements: `s3:GetObject` scoped to the `error-pages/*` prefix for serving error pages,
  and `s3:PutObject` scoped to the `logs/*` prefix for writing access logs.

### Security Response Headers Policies

Adding these response headers can provide information about attacks to the browser and protect users from becoming a
victim if our website gets compromised. While using WAF in our example and applying rules, if our rules are incorrect or
not covered through WAF, it's a good practice to add response header policies.

### Why Response Headers?

Response headers control browser behavior for:

- **Security**: Prevent attacks like XSS, clickjacking, iframe embedding, and more
- **Performance**: Enable compression and caching
- **Compliance**: Help web application meet security standards and regulations

### Module "cloudfront"

This module sets up a **CloudFront CDN distribution** for a static website hosted on S3, with security, caching, and
access control configurations.

#### 1\. Origin Access Controls (OAC)

These lock down the S3 buckets so **only CloudFront can read from them** — not the public directly. It uses AWS's sigv4
signing protocol to authenticate CloudFront's requests to S3.

#### 2\. Response Header Policies

Two policies are defined:

- `security_headers` — Adds HTTP security headers to every response:
    - _X-Content-Type-Options: nosniff_ — prevents MIME-type sniffing
    - _X-Frame-Options: DENY_ — blocks the site from being embedded in iframes
    - _Referrer-Policy_ — controls what referrer info is sent
    - _Strict-Transport-Security (HSTS)_ — forces HTTPS for 1 year, including subdomains
- `cors_policy` — Allows cross-origin GET/HEAD/OPTIONS requests from any origin (wildcard `*`)

#### 3\. The CloudFront Distribution

The core resource, with two **origins**:

| Origin                  | Purpose                                 |
|-------------------------|-----------------------------------------|
| `website_bucket`        | Serves the actual site content          |
| `cloudfront_ops_bucket` | Serves error pages + stores access logs |

Key settings:

- **HTTPS enforced** everywhere (redirect-to-https)
- **IPv6 enabled**
- **Default root object** is `index.html`
- **WAF (Web ACL)** attached for request filtering
- **Geo-restriction** optionally configurable via a variable

#### 4\. Cache Behaviors (in Priority Order)

CloudFront evaluates these top-to-bottom, using the first match:

1. `/assets/img/{bg,misc,portfolio,profile,services}/*` — dynamic block covering 5 specific image subfolders, long-term
   caching (up to 1 year)
2. `/assets/img/*` — catches any remaining images directly under `/img/`
3. `/assets/css/*.css` — stylesheets
4. `/assets/js/*.js` — JavaScript files
5. `/assets/vendor/**` — third-party vendor assets
6. `/error-pages/*` — served from the ops bucket, not the website bucket
7. **Default behavior** — catches everything else (HTML pages), uses a shorter cache TTL

#### 5\. Cache Policies

| Policy          | Default TTL | Max TTL | Use Case        |
|-----------------|-------------|---------|-----------------|
| `static_assets` | 1 day       | 1 year  | Images, CSS, JS |
| `html_content`  | 1 hour      | 1 day   | HTML pages      |

#### 6\. Custom Error Pages

| HTTP Error | Shown Page                                                                         |
|------------|------------------------------------------------------------------------------------|
| 404        | `/error-pages/404.html`                                                            |
| 403        | `/error-pages/404.html` (treats forbidden as not found — hides internal structure) |
| 500        | `/error-pages/500.html`                                                            |

#### 7\. S3 Bucket Policies

Two IAM policies are attached to the S3 buckets, granting CloudFront permission to:

- `s3:GetObject` from the website bucket (to serve content)
- `s3:GetObject` from `/error-pages/*` in the ops bucket
- `s3:PutObject` to `/logs/*` in the ops bucket (to write access logs)

#### Summary Architecture

```
User → WAF → CloudFront → S3 (website bucket)    [content]
                       → S3 (ops bucket)          [error pages + logs]

```

### Security Layer — AWS WAF

AWS Web Application Firewall (WAF) is a security service that can filter malicious requests and provide protection from
intruders. It can block your application from attacks like SQL injection, cross-site scripting, and more. We can add
rate limits to get protection from DDOS attacks. We can restrict access from countries, add captcha, and other rules
based on our use case. We add AWF rules and enable metrics for it.

- AWS WAF must be in `us-east-1` for CloudFront.
- We have added a Rate Limiting rule to allow 20 requests in 5 minutes.

#### WAF Rules We Have Added

- **Common Rule Set**: Blocks SQL injection, XSS, and other OWASP Top 10 attacks
- **Known Bad Inputs**: Blocks requests with malicious patterns
- **Rate Limiting**: Blocks IPs making more than 20 requests per 5 minutes
- WAF rules to block or allow access from specific countries
- We can allow or deny specific IP address or range

### Module "waf"

This module sets up a **Web Application Firewall (WAF)** for a CloudFront distribution on AWS.

#### 1\. Main Resource: `aws_wafv2_web_acl`

The WAF is scoped to `CLOUDFRONT` (meaning it protects a CloudFront distribution globally) and its **default action is
to allow** — traffic is allowed unless a rule blocks it.

#### 2\. Rules (in Priority Order)

| Priority | Rule                                   | Action                          | Purpose                                           |
|----------|----------------------------------------|---------------------------------|---------------------------------------------------|
| 1        | `AWSManagedRulesCommonRuleSet`         | Block (with body size override) | General protections (XSS, bad requests, etc.)     |
| 2        | `AWSManagedRulesKnownBadInputsRuleSet` | Block                           | Blocks known exploit patterns (Log4j, etc.)       |
| 3        | `RateLimitRule`                        | Block                           | Blocks IPs exceeding **2000 req / 5 min**         |
| 4        | `BotControlRuleSet`                    | Block (COMMON level)            | Detects and blocks common bots                    |
| 5        | `AmazonIpReputationList`               | Count only                      | Flags IPs with bad reputation (not blocking yet)  |
| 6        | `AnonymousIpList`                      | Block                           | Blocks VPNs, Tor, proxies                         |
| 7        | `SQLiRuleSet`                          | Block                           | SQL injection protection                          |
| 8        | `LinuxRuleSet`                         | Count only                      | Detects Linux-specific exploits (monitoring mode) |
| 9        | `UnixRuleSet`                          | Count only                      | Detects Unix-specific exploits (monitoring mode)  |
| 10       | `WindowsRuleSet`                       | Block (with shell override)     | Windows exploit protection                        |
| 11       | `block-bad-user-agents`                | Block                           | Blocks scanners like sqlmap and nikto             |

There's also a **commented-out geo-restriction rule** that would block traffic from specific countries if enabled.

#### A Few Things Worth Noting

- **Count vs. Block**: Several rules (IP reputation, Linux, Unix) are set to _count_ instead of block. This is a common
  pattern when you want to **observe traffic first** before committing to blocking it.
- **Rule overrides**: Some rules have specific sub-rules overridden to _allow_ (e.g., `SizeRestrictions_BODY`,
  `WindowsShellCommands_BODY`), likely to prevent false positives on legitimate large uploads or specific request
  patterns.

#### 3\. Supporting Resources

- `aws_wafv2_web_acl_logging_configuration` — Enables logging, but only keeps _BLOCK_ and _COUNT_ events (drops _ALLOW_
  logs to reduce volume).
- `aws_cloudwatch_log_group` — Creates a log group named `aws-waf-logs-<prefix>` (the `aws-waf-logs-` prefix is *
  *required** by AWS) with a 7-day retention period.

### CloudWatch Dashboard for CloudFront Monitoring

Creating a CloudWatch Dashboard and alarms. Alarms have been created for 4xx and 5xx errors. Ideally in production we
usually monitor 403 and 5xx alerts since these apply to webapp domains.

### Module "cloudwatch"

This module sets up **AWS CloudWatch monitoring** for a CloudFront distribution. It has two main parts:

#### 1\. CloudWatch Dashboard

Creates a visual dashboard with three panels:

- **CloudFront Performance** — tracks Cache Hit Rate, Origin Latency, and total Requests
- **Error Rates** — tracks 4xx (client errors) and 5xx (server errors) percentages
- **Data Transfer** — tracks bytes downloaded and uploaded

All panels use a 5-minute interval (`period = 300`) and display data as time-series graphs.

#### 2\. CloudWatch Alarms (4 Total)

Each alarm watches a specific metric and fires if a threshold is breached over multiple evaluation periods. They all
notify via an SNS topic (`var.sns_topic_arn`):

| Alarm                 | Condition             | Sensitivity |
|-----------------------|-----------------------|-------------|
| `high_4xx_error_rate` | 4xx errors \> 5%      | 2 periods   |
| `high_5xx_error_rate` | 5xx errors \> 1%      | 2 periods   |
| `low_cache_hit_rate`  | Cache hit rate \< 80% | 3 periods   |
| `high_origin_latency` | Origin latency \> 3s  | 3 periods   |

> _One thing worth noting_: CloudFront metrics must be read from **us-east-1** regardless of where your distribution
> serves traffic — that's hardcoded and correct, since CloudFront metrics are only published to that region.

### Amazon SNS Topic for CloudFront Alerts

#### Module "sns"

This module sets up an **AWS SNS (Simple Notification Service)** notification system for CloudFront alerts. There are
two resources:

##### 1\. `aws_sns_topic` — The Notification Channel

This creates an **SNS Topic**, which acts as a messaging hub — anyone subscribed to it will receive messages published
to it.

- `name` — dynamically built using a prefix variable (e.g., `myapp-cloudfront-alerts`)
- `tags` — merges common shared tags with topic-specific ones (Name, Type, Purpose)

##### 2\. `aws_sns_topic_subscription` — The Email Subscribers

This subscribes **one or more email addresses** to the topic above.

#### How It Fits Together

```
CloudFront Event / CloudWatch Alarm
      │
      ▼
SNS Topic (cloudfront_alerts)
      │
      ├──► email1@...
      └──► email2@... ← one subscription resource per address

```

When something publishes an alert to this SNS topic (e.g., a CloudWatch alarm detecting high error rates on CloudFront),
**every subscribed email address gets notified**.

> **Note:** _AWS will send a confirmation email to each address before they start receiving alerts — subscriptions
aren't active until confirmed._

### The Outputs

After deployment, you'll get:

- Website URLs ([https://cloudwithdarvin.com](https://cloudwithdarvin.com))
- Website URLs ([https://www.cloudwithdarvin.com](https://www.cloudwithdarvin.com))

![0-Outputs.png](../Screenshot%20verification/0-Outputs.png)

---

### Step 4: Deploy Content and Invalidate Cache

The final stage separates content deployment from infrastructure, allowing static website updates without re-running
Terraform. Static HTML files are in the content folder, and a GitHub Actions workflow (`deploy-infrastructure.yml`)
automates deployment on every merge to the main branch.

### Workflow GitHub Actions

- **`terraform-checkov.yml`** — Automated security scanning framework using Checkov to detect Terraform
  misconfigurations at both repository and pull request (PR) levels.
- **`deploy-infrastructure.yml`** — Terraform workflow to provision infrastructure and deploy the Static Website with
  OIDC, synchronize Website content if something changed, and invalidate a CloudFront cache, forcing edge servers to
  fetch fresh content from the origin.

### Invalidate CloudFront Cache

Create a CloudFront cache invalidation for all paths (`/*`). Without this step, CloudFront would continue serving the
previously cached version for up to 24 hours (the default TTL of the Managed-CachingOptimized cache policy). The
invalidation ensures visitors see the updated content immediately.

#### What is Cache Invalidation?

Cache invalidation removes files from CloudFront edge caches before they expire naturally.

#### When to Use Invalidation

- **Emergency fixes**: Critical bug fixes that can't wait for cache expiry
- **Content updates**: When you need immediate content changes
- **Security patches**: Urgent security updates
- **Marketing campaigns**: Time-sensitive content launches

> We should always provide specific path or files to invalidate.

#### What Happens Under the Hood

1. CloudFront marks all cached objects as stale across its edge locations
2. The next request to each edge node triggers a fresh fetch from your origin (S3, EC2, etc.)
3. Subsequent requests are served from the refreshed cache
4. This pattern is common in **static site deployments** — after uploading new files to S3, you invalidate the
   CloudFront cache so users immediately get the updated content instead of stale cached versions.

---

## Monitoring

The project includes:

**CloudWatch Dashboard:** Performance metrics and error rates

- **CloudWatch Alarms:**

    - High 4xx error rate (\>5%)
    - High 5xx error rate (\>1%)
    - Low cache hit rate (\<80%)
    - High origin latency (\>3 seconds)
- **Access Logs**: Detailed request logs stored in S3

---

## Quick Start

### Step 1 — Fork and Clone

```bash
$ git clone https://github.com/darvin-rakotomalala/s3-static-website
$ cd s3-static-website

```

### Step 2 — Configure Terraform

Edit `s3-static-website/dev-terraform.tfvars` to match your target region and preferences. No secrets go here — just
region, domain name, and default tags.

### Step 3 — Deploy Infrastructure

```bash
$ cd s3-static-website
$ terraform init
$ terraform fmt -recursive
$ terraform validate
$ terraform plan -var-file="dev-terraform.tfvars" -no-color -out=TFplan.JSON
$ terraform apply -var-file="dev-terraform.tfvars" -auto-approve

```

---

## Verification

- After deploying all three steps, the site was live at _[https://cloudwithdarvin.com/](https://cloudwithdarvin.com/)_
  with a secure connection confirmed by the browser.

![1-Website 1.png](../Screenshot%20verification/1-Website%201.png)

![1-Website 2.png](../Screenshot%20verification/1-Website%202.png)

![1-Error page not found.png](../Screenshot%20verification/1-Error%20page%20not%20found.png)

- On the AWS console, the CloudFront distribution showed the alternate domain names (`cloudwithdarvin.com` and
  `www.cloudwithdarvin.com`), the attached ACM certificate, the TLSv1.2\_2021 security policy, and standard logging
  enabled.

![6-cf-distribution detail.png](../Screenshot%20verification/6-cf-distribution%20detail.png)

- The two S3 origins — one for website content and one for the ops bucket — were configured correctly.

![6-cf-distribution origins.png](../Screenshot%20verification/6-cf-distribution%20origins.png)

- The custom error responses are in place — HTTP 403 and 404 errors serve the custom 404 page, while 500 errors serve
  the 500 page, both from the ops bucket's `/error-pages/` prefix.

![6-cf-distribution error pages.png](../Screenshot%20verification/6-cf-distribution%20error%20pages.png)

- The Route 53 hosted zone shows the A records (```root``` and ```www```) aliased to CloudFront, the NS and SOA records,
  and the
  CNAME records created during ACM DNS validation.

![2-Route 53.png](../Screenshot%20verification/2-Route%2053.png)

#### DNSSEC Signing

The DNSSEC signing status is shown as **Active** in the Route 53 hosted zone with the Key Signing Key (KSK) in active
status.

![2-Route DNSSEC Key.png](../Screenshot%20verification/2-Route%20DNSSEC%20Key.png)

### WAF Test — Manual HTTP Requests with curl

The quickest way to test specific WAF rules:

```bash
# Test a SQL injection rule
$ curl -i "https://cloudwithdarvin.com/?id=1' OR '1'='1"

# Test an XSS rule
$ curl -i "https://cloudwithdarvin.com/?q=<script>alert('xss')</script>"

# Test a path traversal rule
$ curl -i "https://cloudwithdarvin.com/../../../../etc/passwd"

# Test a blocked User-Agent (bad bot rule)
$ curl -i -A "sqlmap/1.0" https://cloudwithdarvin.com/

# Test rate limiting (send many requests quickly)
$ for i in {1..200}; do curl -s -o /dev/null -w "%{http_code}" https://cloudwithdarvin.com/; done

```

A **403 response** means WAF blocked the request. A **200** means it passed through.

**Automated Scanning with nikto or nuclei:**

```bash
# Install nikto (web vulnerability scanner)
$ nikto -h https://cloudwithdarvin.com

# Or use nuclei for targeted WAF bypass testing
$ nuclei -u https://cloudwithdarvin.com -t waf-bypass/

```

---

## Troubleshooting

**The Problem**: CSS, JS, and image files are not loaded when accessed on my domain.

**Root Cause**: The HTML source files don't have a metadata when uploaded to the S3 bucket.

![Troubleshooting.png](../Screenshot%20verification/Troubleshooting.png)

**Solution**: In Terraform code, set a `mime_types` for each file.

```hcl
locals {
  mime_types = {
    "html"  = "text/html"
    "css"   = "text/css"
    "js"    = "application/javascript"
    "json"  = "application/json"
    "webp"  = "image/webp"
    "png"   = "image/png"
    "jpg"   = "image/jpeg"
    "jpeg"  = "image/jpeg"
    "svg"   = "image/svg+xml"
    "ico"   = "image/x-icon"
    "woff"  = "font/woff"
    "woff2" = "font/woff2"
    "ttf"   = "font/ttf"
    "txt"   = "text/plain"
  }
}

resource "aws_s3_object" "provision_source_files" {
  bucket = module.s3.s3_bucket_website_id
  for_each = fileset("${var.source_files}/", "**/*.*")

  key           = each.value
  source        = "${var.source_files}/${each.value}"
  content_type = lookup(local.mime_types, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
  etag = filemd5("${var.source_files}/${each.value}")
  cache_control = startswith(each.value, "assets/") ? "public, max-age=31536000, immutable" : "no-cache"
}

```

### Cache Invalidation

After setting up the `mime_types`, CloudFront may still be serving cached content. Go to:

1. **Invalidations tab → Create invalidation**
2. Add path: `/*`
3. Submit and wait ~1 min

After invalidating on path (`/*`), the result becomes the correct page.

---

## Conclusion

In this project, we walked through deploying a production-grade secure static website on AWS using Terraform —
provisioning DNS with Route 53, building the infrastructure with S3, CloudFront, ACM, KMS, WAF, and automating content
deployment through GitHub Actions.

_If you have a static site idea — a portfolio, documentation, a landing page — and were wondering how to host it on AWS
with proper security and automation, **this project has the blueprint**._

---

_Project by Darvin | Deploy Secure Static Website_