# Static Website Infrastructure

https://github.com/stephenabbot/static-website-infrastructure

Multi-domain static website hosting infrastructure using S3, CloudFront, Route53, and ACM with automated SSL certificate management.

## Table of Contents

- [Why](#why)
- [How](#how)
  - [Architecture](#architecture)
  - [Script-Based Deployment](#script-based-deployment)
- [Resources Deployed](#resources-deployed)
- [Prerequisites](#prerequisites)
  - [Deployment Roles](#deployment-roles)
  - [Required Tools](#required-tools)
  - [Domain Requirements](#domain-requirements)
- [Quick Start](#quick-start)
- [Troubleshooting](#troubleshooting)
  - [Certificate Validation Failures](#certificate-validation-failures)
  - [CloudFront Distribution Issues](#cloudfront-distribution-issues)
  - [DNS Resolution Problems](#dns-resolution-problems)
- [Technologies and Services](#technologies-and-services)
  - [Infrastructure as Code](#infrastructure-as-code)
  - [AWS Services](#aws-services)
  - [Development Tools](#development-tools)
- [Copyright](#copyright)

## Why

Static websites require multiple AWS services working together: S3 for storage, CloudFront for global distribution, Route53 for DNS management, and ACM for SSL certificates. Configuring these services manually for multiple domains creates inconsistency, security gaps, and operational overhead. Managing SSL certificate validation, CloudFront distributions, and DNS records across multiple domains becomes complex and error-prone.

This project provides automated infrastructure deployment for multiple static websites with consistent security, performance, and operational patterns. Each domain gets its own S3 bucket, CloudFront distribution, SSL certificate, and DNS configuration while sharing common infrastructure patterns and tagging standards.

The infrastructure is designed to be deployed once and left running while separate projects manage the actual website content stored in S3 buckets. This separation enables infrastructure stability while allowing frequent content updates without infrastructure risk.

This project is designed for GitHub Actions integration and depends on [terraform-aws-deployment-roles](https://github.com/stephenabbot/terraform-aws-deployment-roles) for authentication, which in turn depends on [terraform-aws-cfn-foundation](https://github.com/stephenabbot/terraform-aws-cfn-foundation) for backend infrastructure. The deployment roles project must be configured with appropriate permissions for this project before deployment. GitHub Actions workflow implementation is planned for future releases.

## How

### Architecture

The project uses OpenTofu to deploy complete static website infrastructure for multiple domains through dynamic discovery. OpenTofu scans the projects directory for domain.tf files and creates infrastructure for each discovered domain-environment combination. This enables adding new domains by copying templates without modifying the root configuration.

Each domain receives dedicated infrastructure including an S3 bucket with versioning and encryption, a CloudFront distribution with Origin Access Control, an ACM certificate with DNS validation, and Route53 hosted zone with DNS records. All resources follow consistent naming patterns and include comprehensive tagging for management and cost allocation.

SSL certificates are automatically validated using DNS records created in the Route53 hosted zone. CloudFront distributions are configured with security headers, compression, and HTTP-to-HTTPS redirects. S3 buckets are secured with public access blocks and bucket policies that only allow CloudFront access.

Infrastructure outputs are published to SSM Parameter Store at predictable paths, enabling content management projects to discover bucket names, distribution IDs, and other resource identifiers without hardcoding values. This loose coupling allows infrastructure and content projects to evolve independently.

### Script-Based Deployment

Deployment scripts handle all operational complexity including prerequisite validation, role assumption, backend configuration, and OpenTofu execution. The scripts validate git repository state, check for deployment role availability, and configure backend settings dynamically from foundation infrastructure.

The deployment process assumes the deployment role created by the [terraform-aws-deployment-roles](https://github.com/stephenabbot/terraform-aws-deployment-roles) project, ensuring consistent authentication and permissions. Backend configuration is retrieved from SSM parameters published by the foundation project, eliminating hardcoded bucket names and enabling shared state management.

Idempotent operations allow running deployment scripts multiple times safely. The scripts detect existing infrastructure and perform updates rather than failing. Domain creation scripts generate new domain configurations from templates. Resource listing scripts provide complete inventory of deployed infrastructure with status checks.

## Resources Deployed

For each domain-environment combination, the following resources are created:

- S3 bucket for static website storage with versioning, encryption, and public access blocks
- CloudFront distribution with Origin Access Control, compression, and security headers
- ACM certificate for SSL/TLS with DNS validation through Route53
- Route53 hosted zone with A and AAAA records pointing to CloudFront
- Route53 domain registration with automatic nameserver updates
- S3 bucket policy allowing CloudFront access while blocking direct public access
- Coming soon page uploaded to S3 bucket as placeholder content
- SSM parameters publishing bucket names, distribution IDs, and certificate ARNs

All resources include comprehensive tags for cost allocation, ownership tracking, and resource management. Bucket names incorporate domain names and environments for uniqueness. CloudFront distributions are configured for optimal performance with PriceClass_100 covering US and Europe.

## Prerequisites

### Deployment Roles

This project requires [terraform-aws-deployment-roles](https://github.com/stephenabbot/terraform-aws-deployment-roles) to be deployed with appropriate permissions. The deployment role must include:

- S3 permissions for bucket creation, policy management, and object operations
- CloudFront permissions for distribution creation and Origin Access Control management
- Route53 permissions for hosted zone creation, record management, and domain registration
- ACM permissions for certificate creation, validation, and management
- SSM permissions for parameter creation and management

Deploy the [terraform-aws-deployment-roles](https://github.com/stephenabbot/terraform-aws-deployment-roles) project first and configure it with a deployment policy that includes all required permissions for static website infrastructure. The deployment role ARN will be discovered automatically through SSM Parameter Store.

### Required Tools

The following tools must be installed and available in your PATH:

- OpenTofu version 1.0 or higher for infrastructure deployment and state management
- AWS CLI version 2.x for AWS service interaction and credential management
- Bash version 4.x or higher for script execution and automation
- jq for JSON processing in deployment scripts and parameter handling
- Git for repository information detection and version control

### Domain Requirements

For each domain you plan to deploy:

- Domain must be registered through Route53 or have nameservers pointed to Route53
- Domain must not have existing hosted zones that conflict with the deployment
- Domain must be available for ACM certificate creation in the us-east-1 region
- Domain must not exceed AWS limits for hosted zones or certificates per account

The deployment automatically creates Route53 hosted zones and updates nameservers for Route53-registered domains. For domains registered elsewhere, you must manually update nameservers to point to the created hosted zone.

## Quick Start

Clone the repository and navigate to the project directory:

```bash
git clone https://github.com/stephenabbot/static-website-infrastructure.git
cd static-website-infrastructure
```

Create a new domain configuration:

```bash
./scripts/create-domain.sh example.com
```

This creates a new directory at projects/example-com/prd with a domain.tf file specifying the domain name. The domain name is automatically converted to a safe format for directory names.

**Example websites deployed using this project:**
- [stephenabbot.com](https://stephenabbot.com) - Personal website
- [denverbites.com](https://denverbites.com) - Denver food blog  
- [denverbytes.com](https://denverbytes.com) - Denver tech blog

Deploy the infrastructure for all configured domains:

```bash
./scripts/deploy.sh
```

The deployment script will validate prerequisites, assume the deployment role, configure the backend, and create infrastructure for all discovered domains. SSL certificate validation may take several minutes to complete.

Verify the deployment and check domain status:

```bash
./scripts/list-deployed-resources.sh
```

Test the deployed website by visiting https://example.com in a browser. You should see a coming soon page served through CloudFront with a valid SSL certificate.

## Troubleshooting

### Certificate Validation Failures

If ACM certificate validation fails, check:

- The Route53 hosted zone exists and contains the validation DNS records
- The domain nameservers point to the Route53 hosted zone nameservers
- DNS propagation has completed, which can take up to 48 hours
- The domain is not already covered by another certificate in the same account

Use dig or nslookup to verify that DNS validation records are resolvable from external DNS servers. Certificate validation requires the validation records to be publicly resolvable.

### CloudFront Distribution Issues

If the CloudFront distribution is not serving content correctly, verify:

- The S3 bucket policy allows access from the CloudFront distribution
- The Origin Access Control is properly configured and attached to the distribution
- The distribution status is "Deployed" rather than "In Progress"
- The coming soon page exists in the S3 bucket at the root path

CloudFront distributions can take 15-20 minutes to fully deploy. Check the distribution status in the AWS console and wait for deployment to complete before testing.

### DNS Resolution Problems

If the domain does not resolve to the CloudFront distribution, check:

- The Route53 hosted zone contains A and AAAA records pointing to CloudFront
- The domain nameservers are set to the Route53 hosted zone nameservers
- DNS propagation has completed, which varies by location and DNS provider
- No conflicting DNS records exist in other hosted zones or DNS providers

Use online DNS propagation checkers to verify that DNS changes have propagated globally. DNS changes can take several hours to propagate depending on TTL values and DNS provider caching.

## Technologies and Services

### Infrastructure as Code

- OpenTofu for infrastructure deployment and state management with provider compatibility
- Terraform modules for reusable domain infrastructure and consistent tagging patterns
- Bash scripting for deployment automation and operational workflows

### AWS Services

- S3 for static website storage with versioning, encryption, and lifecycle management
- CloudFront for global content distribution with Origin Access Control and security headers
- Route53 for DNS management, hosted zones, and domain registration
- ACM for SSL/TLS certificate management with automatic DNS validation
- SSM Parameter Store for infrastructure output publishing and service discovery

### Development Tools

- AWS CLI for service interaction and resource management
- Git for version control and repository metadata detection
- jq for JSON processing and parameter manipulation
- HTML/CSS for coming soon page templates and placeholder content

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

© 2025 Stephen Abbot - MIT License
