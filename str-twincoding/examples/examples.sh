#!/bin/bash
set -euo pipefail

source "$(dirname "$(readlink -f "$0")")/../env.sh"

# The repository dir
echo "======== Using repository: $STRHOME/repository ========"
repository="$STRHOME/repository"
mkdir -p "$repository"

# Generate some random data to a temp file
echo "======== Generating random data ========"
file_name="file_1MB.dat"
file_path=$(storage.sh repo --path "$repository" tmp_file_path --file "$file_name")
[ -f "$file_path" ] || dd if=/dev/urandom of="$file_path" bs=1M count=1

# Generate a test encryption key
echo "======== Generating test encryption key ========"
key_name="test_key"
key_path=$(storage.sh repo --path "$repository" tmp_file_path --file "$key_name")
[ -f "$key_path" ] || ssh-keygen -t rsa -f "$key_path" -N ""

# START_EXAMPLES
# Encode a file, writing n files for each of the two node types to a ".encoded" directory.
echo "======== Encoding file ========"
encoded_file_path=$(storage.sh repo --path "$repository" file_path --file "$file_name")
storage.sh encode \
  --path "$file_path" \
  --output_path "$encoded_file_path" \
  --encoding0 reed_solomon --k0 3 --n0 5 \
  --encoding1 reed_solomon --k1 3 --n1 5 \
  --overwrite \
  --key_path "$key_path"

# This import command is equivalent to the above encode, using the default repository path and encoding type.
echo "======== Importing file ========"
storage.sh import --overwrite --key_path "$key_path" "$file_path"

# List files in the repository.
echo "======== Listing files in repository ========"
storage.sh repo --path "$repository" list

# Decode a file from an encoded storage directory, tolerant of missing files (erasures).
echo "======== Decoding file ========"
recovered_file=$(storage.sh repo --path "$repository" tmp_file_path --file "recovered_${file_name}")
storage.sh decode \
  --encoded "$encoded_file_path" \
  --recovered "$recovered_file" \
  --overwrite \
  --key_path "$key_path"

# Compare the original and decoded files.
echo "======== Comparing original and decoded files ========"
cmp -s "$file_path" "$recovered_file" && echo "Passed" || echo "Failed"


# Prepare node recovery: Generate shard recovery source files for restoration of
echo "======== Preparing for node recovery ========"
# node type 1 index 0, using 3 (k) type 0 node sources (helper nodes),
recover_node_type=1
recover_node_index=0
for helper_node_index in 0 1 2
do
  helper_node_type=0
  helper_shard_file=$(storage.sh repo --path "$repository" shard_path \
      --file "$file_name" --node_type $helper_node_type --node_index $helper_node_index)
  recovery_source_file=$(storage.sh repo --path "$repository" recovery_file_path \
      --file "$file_name" --recover_node_type $recover_node_type --recover_node_index $recover_node_index \
      --helper_node_index "$helper_node_index")
  storage.sh generate_recovery_file \
    --recover_node_type $recover_node_type \
    --recover_node_index $recover_node_index \
    --recover_encoding reed_solomon --k 3 --n 5 \
    --data_path "$helper_shard_file" \
    --output_path "$recovery_source_file" \
    --overwrite
done


# Complete node recovery: Recover the shard for node type 1 index 0 from the k (3) recovery files.
echo "======== Recovering node ========"
recovered_shard_file=$(storage.sh repo --path "$repository" tmp_file_path \
    --file "recovered_${file_name}_type${recover_node_type}_node${recover_node_index}.dat")
storage.sh recover_node \
  --k 3 --n 5 --encoding reed_solomon \
  --recover_node_type $recover_node_type \
  --recover_node_index $recover_node_index \
  --files_dir "$encoded_file_path" \
  --output_path "$recovered_shard_file" \
  --overwrite

# Compare the original and recovered data shards.
echo "======== Comparing original and recovered data shards ========"
original_shard_file=$(storage.sh repo --path "$repository" shard_path \
    --file "$file_name" --node_type 1 --node_index 0)
cmp -s "$original_shard_file" "$recovered_shard_file" && echo "Passed" || echo "Failed"

# END_EXAMPLES
