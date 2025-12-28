# Prerequisites

## Required Tools

- **OpenTofu** version 1.0 or higher for infrastructure deployment
- **AWS CLI** version 2.x for AWS service interaction
- **Bash** version 4.x or higher for script execution
- **jq** for JSON processing in deployment scripts
- **Git** for repository information detection

## AWS Account Requirements

- AWS account with appropriate permissions for S3, CloudFront, Route53, ACM, and SSM
- Domains registered through Route53 or external registrar with nameserver control
- No existing hosted zones that conflict with target domains
- Certificate limits not exceeded in us-east-1 region

## Foundation Infrastructure Dependencies

This project requires two foundation projects to be deployed first:

- [**terraform-aws-cfn-foundation**](https://github.com/stephenabbot/terraform-aws-cfn-foundation) - Provides S3 backend bucket and DynamoDB lock table
- [**terraform-aws-deployment-roles**](https://github.com/stephenabbot/terraform-aws-deployment-roles) - Provides OIDC-based deployment roles for GitHub Actions

### Backend Configuration

The deployment scripts automatically retrieve backend configuration from SSM parameters:

- `/terraform/foundation/s3-state-bucket` - Terraform state bucket name
- `/terraform/foundation/dynamodb-lock-table` - State locking table name

### Deployment Role Configuration

For GitHub Actions deployment, the following role must exist:

- Role ARN: `arn:aws:iam::{ACCOUNT_ID}:role/gharole-website-infrastructure-prd`
- SSM Parameter: `/deployment-roles/website-infrastructure/role-arn`

## Domain Requirements

- Domain must be available for Route53 hosted zone creation
- Domain must not have existing ACM certificates that would conflict
- For external registrars, nameserver update capability required
- DNS propagation time of up to 48 hours should be expected

## Local Development Setup

For local development with admin credentials:

- AWS CLI configured with appropriate profile
- Credentials with permissions for all required AWS services
- Git repository with proper remote URL configured

## GitHub Actions Setup

For automated deployment:

- Repository secrets configured with AWS_ACCOUNT_ID
- OIDC provider configured in AWS account
- Deployment role with trust relationship to GitHub repository
