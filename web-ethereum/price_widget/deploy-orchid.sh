#!/bin/bash
# Deploy the dapp widget to the Orchid S3 bucket. (See also IPFS).

set -euxo pipefail

FLUTTER="${FLUTTER:-$FLUTTER_STABLE}"; $FLUTTER --version | grep -i channel
base=$(dirname "$0"); cd $base

sh build.sh

# update base tag
sed -i '' 's/<base href="\/">/<base href="https:\/\/account.orchid.com\/widget\/">/' build/web/index.html

# sync
aws s3 sync --acl public-read --delete ./build/web/ s3://account.orchid.com/widget/ --profile $AWS_PROFILE_ORCHID

bucket="account.orchid.com"
distribution=$(aws --output json cloudfront list-distributions --profile $AWS_PROFILE_ORCHID | jq -r --arg bucket "$bucket" '.DistributionList.Items[] | select(.Status=="Deployed") | select(.Aliases.Items[] | contains($bucket)) | .Id')
AWS_MAX_ATTEMPTS=10 aws cloudfront create-invalidation --distribution-id "$distribution" --paths "/*" --profile $AWS_PROFILE_ORCHID

