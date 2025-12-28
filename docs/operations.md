# Operations Guide

## Daily Operations

### Monitoring Deployed Resources

Check status of all deployed domains:
```bash
./scripts/list-deployed-resources.sh
```

This displays:
- Domain configurations
- S3 bucket status and content
- CloudFront distribution status
- Route53 DNS records
- ACM certificate status

### Verifying System Health

Run prerequisite checks:
```bash
./scripts/verify-prerequisites.sh
```

Validates:
- Required tools installation
- AWS credentials and permissions
- Foundation infrastructure dependencies

## Domain Management

### Adding New Domains

1. Create domain configuration:
```bash
./scripts/create-domain.sh newdomain.com
```

2. Deploy infrastructure:
```bash
./scripts/deploy.sh
```

3. Verify deployment:
```bash
./scripts/list-deployed-resources.sh
```

### Removing Domains

1. Remove domain directory:
```bash
rm -rf projects/newdomain-com/
```

2. Redeploy to remove resources:
```bash
./scripts/deploy.sh
```

**Warning**: This will destroy all resources for the removed domain.

## Content Management

### Updating Website Content

Content updates are handled by individual content projects. See [content deployment guide](https://github.com/stephenabbot/website-infrastructure/blob/main/docs/content-deployment.md) for details.

### Emergency Content Rollback

If content deployment fails, restore previous version:

1. Access S3 bucket in AWS Console
2. Navigate to object versions
3. Restore previous version of affected files
4. Create CloudFront invalidation

## Security Operations

### Certificate Management

Certificates are automatically managed by ACM:
- Automatic renewal before expiration
- DNS validation through Route53
- No manual intervention required

Monitor certificate status:
```bash
aws acm list-certificates --region us-east-1
```

### Security Header Verification

Test security headers on deployed sites:
```bash
curl -I https://yourdomain.com
```

Should include:
- `Strict-Transport-Security`
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Content-Security-Policy`

### Access Log Analysis

Enable CloudFront access logs for security monitoring:
1. Create dedicated S3 bucket for logs
2. Configure CloudFront distribution logging
3. Analyze logs for suspicious activity

## Backup and Recovery

### Infrastructure Recovery

Infrastructure is fully recoverable through code:
1. Ensure foundation projects are deployed
2. Run deployment script: `./scripts/deploy.sh`
3. All resources will be recreated

### Content Recovery

S3 versioning enables content recovery:
1. Access S3 bucket in AWS Console
2. Navigate to object versions
3. Restore required version
4. Invalidate CloudFront cache

### State File Recovery

Terraform state is backed up in S3:
- Automatic versioning enabled
- Cross-region replication (if configured)
- DynamoDB locking prevents corruption

## Performance Optimization

### CloudFront Cache Optimization

Monitor cache hit ratios:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=DISTRIBUTION_ID \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average
```

### Content Optimization

- Compress images before upload
- Use modern image formats (WebP, AVIF)
- Minimize CSS and JavaScript
- Implement proper cache headers

## Cost Management

### Cost Monitoring

Monitor costs by domain using resource tags:
- Project tag for overall project costs
- Domain tag for per-domain costs
- Environment tag for environment separation

### Cost Optimization

- Review CloudFront usage patterns
- Optimize cache behaviors
- Consider S3 lifecycle policies for old versions
- Monitor data transfer costs

## Troubleshooting

### Common Issues

**Deployment Failures**
1. Check AWS credentials: `aws sts get-caller-identity`
2. Verify foundation infrastructure is deployed
3. Check for resource limits (certificates, hosted zones)
4. Review Terraform logs for specific errors

**DNS Resolution Issues**
1. Verify nameservers point to Route53
2. Check DNS propagation: `dig yourdomain.com`
3. Wait for global DNS propagation (up to 48 hours)

**Certificate Validation Failures**
1. Ensure DNS records exist for validation
2. Check nameserver configuration
3. Wait for DNS propagation
4. Verify no conflicting certificates exist

For detailed troubleshooting, see [troubleshooting guide](https://github.com/stephenabbot/website-infrastructure/blob/main/docs/troubleshooting.md).

## Maintenance Schedule

### Weekly
- Review CloudFront cache hit ratios
- Check certificate expiration dates
- Monitor cost reports

### Monthly
- Review access logs for security issues
- Update dependencies in content projects
- Verify backup procedures

### Quarterly
- Review and update security headers
- Assess cost optimization opportunities
- Update documentation for any changes

## Emergency Procedures

### Complete Infrastructure Failure

1. Verify foundation infrastructure is intact
2. Check AWS service health dashboard
3. Redeploy infrastructure: `./scripts/deploy.sh`
4. Verify all domains are accessible
5. Notify stakeholders of resolution

### Security Incident

1. Review CloudFront and S3 access logs
2. Check for unauthorized changes
3. Rotate deployment credentials if compromised
4. Update security groups and policies as needed
5. Document incident and response

### Data Loss

1. Check S3 versioning for affected objects
2. Restore from most recent good version
3. Invalidate CloudFront cache
4. Verify content integrity
5. Implement additional backup measures if needed
