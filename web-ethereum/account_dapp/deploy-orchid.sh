#!/bin/bash
# Deploy the dapp to the Orchid S3 bucket. (See also IPFS).

set -euxo pipefail

export FLUTTER="${FLUTTER:-$FLUTTER_STABLE}"; $FLUTTER --version | grep -i channel
base=$(dirname "$0"); cd $base

# S3 bucket 
bucket="account.orchid.com"

echo "Building..."
sh build.sh

echo "Creating snapshot..."
# Back up the current contents to a snapshot in the bucket:
# Exclude "snapshots/*" so we don't recursively copy prior snapshots into the new one :)
ts=$(date -u +%Y%m%d-%H%M%S)
echo "Creating in-bucket snapshot at s3://$bucket/snapshots/$ts/ ..."
aws s3 sync s3://$bucket/ s3://$bucket/snapshots/$ts/ \
  --exclude "snapshots/*" \
  --delete \
  --profile $AWS_PROFILE_ORCHID

# Show the new snapshot 
echo "Available snapshots:"
aws s3 ls s3://$bucket/snapshots/ --profile $AWS_PROFILE_ORCHID

# To roll back:
#   SNAPSHOT_TS="<TIMESTAMP>"
#   aws s3 sync s3://$bucket/snapshots/$SNAPSHOT_TS/ s3://$bucket/ --delete --profile $AWS_PROFILE_ORCHID
# Then invalidate CloudFront.

echo "Deploying..."
# Exclude the snapshots path so --delete does not remove stored snapshots.
aws s3 sync --acl public-read --delete --exclude "snapshots/*" ./build/web/ s3://$bucket/ --profile $AWS_PROFILE_ORCHID

echo "Updating Cloudfront..."
distribution=$(aws --output json cloudfront list-distributions --profile $AWS_PROFILE_ORCHID | jq -r --arg bucket "$bucket" '.DistributionList.Items[] | select(.Status=="Deployed") | select(.Aliases.Items[] | contains($bucket)) | .Id')
AWS_MAX_ATTEMPTS=10 aws cloudfront create-invalidation --distribution-id "$distribution" --paths "/*" --profile $AWS_PROFILE_ORCHID

echo "Deploying widget..."
../dapp_widget/deploy-orchid.sh


