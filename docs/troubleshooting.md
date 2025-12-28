# Troubleshooting

## Certificate Validation Issues

### Symptoms
- ACM certificate stuck in "Pending validation" status
- Deployment fails during certificate validation step
- Certificate validation timeout after 30 minutes

### Diagnosis Steps
1. Check Route53 hosted zone contains validation records
2. Verify domain nameservers point to Route53 hosted zone
3. Test DNS resolution of validation records externally
4. Confirm no conflicting certificates exist

### Resolution
- Ensure nameservers are correctly configured
- Wait for DNS propagation (up to 48 hours)
- Delete conflicting certificates if found
- Re-run deployment after DNS propagation

## CloudFront Distribution Problems

### Symptoms
- Distribution shows "In Progress" status for extended periods
- Content not serving correctly through CloudFront
- SSL certificate errors when accessing domain

### Diagnosis Steps
1. Check distribution status in AWS Console
2. Verify Origin Access Control configuration
3. Test S3 bucket policy allows CloudFront access
4. Confirm certificate is attached to distribution

### Resolution
- Wait for distribution deployment (15-20 minutes typical)
- Verify S3 bucket policy matches CloudFront distribution ARN
- Ensure certificate validation completed before distribution creation

## DNS Resolution Failures

### Symptoms
- Domain does not resolve to CloudFront distribution
- DNS queries return NXDOMAIN or wrong IP addresses
- Intermittent resolution issues

### Diagnosis Steps
1. Check Route53 hosted zone contains A and AAAA records
2. Verify nameservers match hosted zone nameservers
3. Test DNS propagation using online tools
4. Confirm no conflicting DNS records exist

### Resolution
- Update nameservers to Route53 hosted zone values
- Wait for DNS propagation globally
- Remove conflicting DNS records from other providers

## Deployment Script Failures

### Symptoms
- Backend configuration not found errors
- Role assumption failures
- Terraform state lock errors

### Diagnosis Steps
1. Verify foundation infrastructure is deployed
2. Check SSM parameters exist for backend configuration
3. Confirm deployment role exists and is assumable
4. Check for stale DynamoDB locks

### Resolution
- Deploy terraform-aws-cfn-foundation first
- Deploy terraform-aws-deployment-roles with correct permissions
- Clear stale locks using deployment script logic
- Verify AWS credentials have required permissions

## Domain Creation Issues

### Symptoms
- create-domain.sh script fails with validation errors
- Template files not found
- Domain directory already exists

### Diagnosis Steps
1. Verify domain name format is valid
2. Check template directory exists
3. Confirm domain not already configured

### Resolution
- Use valid domain format (example.com)
- Ensure templates/new-domain directory exists
- Remove existing domain directory if recreating

## S3 Bucket Access Problems

### Symptoms
- 403 Forbidden errors when accessing content
- CloudFront cannot access S3 objects
- Bucket policy errors during deployment

### Diagnosis Steps
1. Check S3 bucket policy allows CloudFront access
2. Verify Origin Access Control is properly configured
3. Confirm public access blocks are correctly set

### Resolution
- Ensure bucket policy includes correct CloudFront distribution ARN
- Verify Origin Access Control is attached to distribution
- Do not modify public access blocks (should remain blocked)

## GitHub Actions Deployment Issues

### Symptoms
- OIDC authentication failures
- Permission denied errors
- Backend configuration not found

### Diagnosis Steps
1. Verify AWS_ACCOUNT_ID secret is configured
2. Check OIDC provider exists in AWS account
3. Confirm deployment role trust relationship
4. Verify foundation infrastructure SSM parameters

### Resolution
- Configure repository secrets correctly
- Set up OIDC provider with correct thumbprint
- Update deployment role trust policy for repository
- Deploy foundation infrastructure first
