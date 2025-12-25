#!/bin/bash
# scripts/list-deployed-resources.sh - List all deployed domain resources

set -euo pipefail

# Change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

# Disable AWS CLI pager
export AWS_PAGER=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "📋 LISTING DEPLOYED DOMAIN RESOURCES"
echo ""

# Check if infrastructure-outputs.json exists
if [ ! -f "infrastructure-outputs.json" ]; then
    print_error "infrastructure-outputs.json not found"
    print_error "Run ./scripts/deploy.sh first"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed"
    exit 1
fi

# Parse and display deployed domains
print_status "Deployed Domains:"
echo ""

jq -r '.deployed_domains.value | to_entries[] | "\(.key)|\(.value.domain_name)|\(.value.environment)"' infrastructure-outputs.json | while IFS='|' read -r key domain_name environment; do
    echo "🌐 Domain: $domain_name ($environment)"
    echo "   Key: $key"
    
    # Get domain details
    bucket_name=$(jq -r ".deployed_domains.value[\"$key\"].bucket_name" infrastructure-outputs.json)
    distribution_id=$(jq -r ".deployed_domains.value[\"$key\"].cloudfront_distribution_id" infrastructure-outputs.json)
    cert_arn=$(jq -r ".deployed_domains.value[\"$key\"].certificate_arn" infrastructure-outputs.json)
    zone_id=$(jq -r ".deployed_domains.value[\"$key\"].hosted_zone_id" infrastructure-outputs.json)
    
    echo "   S3 Bucket: $bucket_name"
    echo "   CloudFront: $distribution_id"
    echo "   Certificate: ${cert_arn##*/}"
    echo "   Hosted Zone: $zone_id"
    echo ""
done

# Display Terraform state resources
print_status "Terraform State Resources:"
echo ""

if tofu state list > /dev/null 2>&1; then
    tofu state list | sort | while read -r resource; do
        echo "  • $resource"
    done
else
    print_warning "Could not access Terraform state"
fi

echo ""

# Display AWS resource status by service
print_status "AWS Resource Status:"
echo ""

# S3 Buckets
print_status "S3 Buckets:"
jq -r '.deployed_domains.value | to_entries[] | .value.bucket_name' infrastructure-outputs.json | while read -r bucket_name; do
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        print_success "  ✓ $bucket_name (exists)"
    else
        print_error "  ✗ $bucket_name (missing)"
    fi
done

echo ""

# CloudFront Distributions
print_status "CloudFront Distributions:"
jq -r '.deployed_domains.value | to_entries[] | .value.cloudfront_distribution_id' infrastructure-outputs.json | while read -r distribution_id; do
    status=$(aws cloudfront get-distribution --id "$distribution_id" --query 'Distribution.Status' --output text 2>/dev/null || echo "ERROR")
    if [ "$status" = "Deployed" ]; then
        print_success "  ✓ $distribution_id ($status)"
    elif [ "$status" = "ERROR" ]; then
        print_error "  ✗ $distribution_id (missing)"
    else
        print_warning "  ⚠ $distribution_id ($status)"
    fi
done

echo ""

# Route53 Hosted Zones
print_status "Route53 Hosted Zones:"
jq -r '.deployed_domains.value | to_entries[] | "\(.value.hosted_zone_id)|\(.value.domain_name)"' infrastructure-outputs.json | while IFS='|' read -r zone_id domain_name; do
    if aws route53 get-hosted-zone --id "$zone_id" > /dev/null 2>&1; then
        record_count=$(aws route53 list-resource-record-sets --hosted-zone-id "$zone_id" --query 'length(ResourceRecordSets)' --output text)
        print_success "  ✓ $zone_id ($domain_name) - $record_count records"
    else
        print_error "  ✗ $zone_id ($domain_name) (missing)"
    fi
done

echo ""

# ACM Certificates
print_status "ACM Certificates:"
jq -r '.deployed_domains.value | to_entries[] | "\(.value.certificate_arn)|\(.value.domain_name)"' infrastructure-outputs.json | while IFS='|' read -r cert_arn domain_name; do
    status=$(aws acm describe-certificate --certificate-arn "$cert_arn" --query 'Certificate.Status' --output text 2>/dev/null || echo "ERROR")
    if [ "$status" = "ISSUED" ]; then
        print_success "  ✓ ${cert_arn##*/} ($domain_name) - $status"
    elif [ "$status" = "ERROR" ]; then
        print_error "  ✗ ${cert_arn##*/} ($domain_name) (missing)"
    else
        print_warning "  ⚠ ${cert_arn##*/} ($domain_name) - $status"
    fi
done

echo ""

# SSM Parameters
print_status "SSM Parameters:"
jq -r '.deployed_domains.value | to_entries[] | .value.domain_name' infrastructure-outputs.json | while read -r domain_name; do
    param_count=$(aws ssm get-parameters-by-path --region us-east-1 --path "/static-website/infrastructure/$domain_name/" --query 'length(Parameters)' --output text 2>/dev/null || echo "0")
    if [ "$param_count" -gt 0 ]; then
        print_success "  ✓ $domain_name ($param_count parameters)"
    else
        print_warning "  ⚠ $domain_name (no parameters found)"
    fi
done

echo ""
print_status "Resource listing complete"
