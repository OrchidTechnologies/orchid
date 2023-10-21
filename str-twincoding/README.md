
## About

Twin Coding is a hybrid encoding scheme that works with any two linear coding schemes and combines
them to achieve a space-bandwidth tradeoff, minimizing the amount of data that must be transferred
between storage nodes in order to recover a lost shard of data. In contrast to a traditional
erasure scheme, in which restoration of a lost node requires a full reconstruction of the original
file, Twin Coding allows for the recovery of a lost data shard with data transfer totalling exactly
the size of the lost data shard, with no additional transfer overhead.

This repository contains an implementation of Twin Coding, as well as a command line API for encoding 
files, decoding files with erasures, and optimally recovering lost shards.

See `twin_coding.py` for an explanation of the algorithm, example code, and a link to the original paper.

## Installation

```
# Create a virtual environment
python3 -m venv venv
```

```
# Activate the virtual environment
# For macOS and Linux:
source venv/bin/activate
# For Windows:
.\venv\Scripts\activate
```

```
# Install the dependencies
pip install -r requirements.txt
```

## Usage

See also `examples.sh`.

```

# Generate some random data
dd if=/dev/urandom of="file_1KB.dat" bs=1K count=1

# Encode a file, writing n files for each of the two node types to a ".encoded" directory.
./storage.sh encode \
  --path "file_1KB.dat" \
  --encoding0 reed_solomon --k0 3 --n0 5 \
  --encoding1 reed_solomon --k1 3 --n1 5 \
  --overwrite

# Decode a file from an encoded storage directory, tolerant of missing files (erasures).
./storage.sh decode \
  --encoded "file_1KB.dat.encoded" \
  --recovered "recovered.dat" \
  --overwrite

# Compare the original and decoded files.
cmp -s "file_1KB.dat" "recovered.dat" && echo "Passed" || echo "Failed"


# Generate shard recovery files: Using k (3) type 0 node sources (helper nodes), generate recovery
# files for restoration of node type 1 index 0.
for helper_node in 0 1 2
do
./storage.sh generate_recovery_file \
  --recover_node_index 0 \
  --recover_encoding reed_solomon --k 3 --n 5 \
  --data_path "file_1KB.dat.encoded/type0_node${helper_node}.dat" \
  --output_path "recover_type1_node0/recover_${helper_node}.dat" \
  --overwrite
done

# Recover the shard for node type 1 index 0 from the k (3) recovery files.
./storage.sh recover_node \
  --k 3 --n 5 --encoding reed_solomon \
  --files_dir "recover_type1_node0" \
  --output_path "recovered_type1_0.dat" \
  --overwrite

# Compare the original and recovered data shards.
cmp -s "file_1KB.dat.encoded/type1_node0.dat" "recovered_type1_0.dat" && echo "Passed" || echo "Failed"

```

