# Generate a test file
dd if=/dev/urandom of="foo_file.dat" bs=1K count=1 status=none

# Import a file into the default local repository with default encoding
storage.sh import foo_file.dat

# List the repository
storage.sh repo list

# Start a test provider server cluster
examples/test-cluster.sh start 5001 5002 5003 5004 5005

# Confirm that the test servers are running
examples/test-cluster.sh list

# "Discover" these providers, adding them to our known provider list
# This will normally be done via the directory service and performed at file push time.
providers.sh add 5001 5002 5003 5004 5005

# List the known providers
providers.sh list

# Start the monitor application (in another window)
# tmux split
monitor.sh --update 1

# Push the file by name
# (Observe the availability of the file in the monitor)
storage.sh push foo_file.dat

# Delete a shard from one of the providers
# (Observe the availability is reduced as a unique shard is lost)
storage.sh delete_shard --provider 5001 foo_file.dat --node_type 0 --node_index 0

# Request that the provider rebuild the lost node from specified other nodes in the cluster.
storage.sh request_repair --to_provider 5001 foo_file.dat --node_type 0 --node_index 0 --from_providers 5002 5003 5004
...


# Shut down the servers
examples/test-cluster.sh stop

