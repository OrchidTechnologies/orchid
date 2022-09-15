#!/bin/bash
# Deploy the dapp to the Orchid S3 bucket. (See also IPFS).

set -euxo pipefail

export FLUTTER="${FLUTTER:-$FLUTTER_STABLE}"; $FLUTTER --version | grep -i channel
base=$(dirname "$0"); cd $base

echo "Building..."
sh build.sh

echo "Deploying..."
aws s3 sync --acl public-read --delete ./build/web/ s3://account.orchid.com/ --profile $AWS_PROFILE_ORCHID

bucket="account.orchid.com"
distribution=$(aws --output json cloudfront list-distributions $AWS_PROFILE_ORCHID | jq -r --arg bucket "$bucket" '.DistributionList.Items[] | select(.Status=="Deployed") | select(.Aliases.Items[] | contains($bucket)) | .Id')
aws cloudfront create-invalidation --distribution-id "$distribution" --paths "/*" $AWS_PROFILE_ORCHID

echo "Deploying widget..."
../dapp_widget/deploy.sh

