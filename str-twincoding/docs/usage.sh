# Generate some test files
test-content.sh

# Import a file into the default local repository with default encoding
storage.sh import data/foo_file.dat

# List the repository
storage.sh repo list

# Start a test provider server cluster
test-cluster.sh start 5001 5002 5003 5004 5005

# Confirm that the test servers are running
test-cluster.sh list

# "Discover" these providers, adding them to our known provider list
# This will normally be done via the directory service and performed at file push time.
test-discover.sh 5001 5002 5003 5004 5005

# Start the monitor application (in another window)
monitor.sh --update 1

# Push the file by name
storage.sh push foo_file.dat

# TODO:
# Monitor file availability while:
#   Observing resilient upload progress
#   Killing servers and prompting efficient rebuilds

# Shut downt the servers
test-cluster.sh stop
