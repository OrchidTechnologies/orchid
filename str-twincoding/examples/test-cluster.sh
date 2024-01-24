#!/bin/bash
source "$(dirname "$0")/../env.sh"

##
## Start a test provider server cluster, e.g.
## test-cluster.sh start 5001 5002 5003 5004 5005
##
## Confirm that the test servers are running
## test-cluster.sh list
##
## Shut down the servers
## test-cluster.sh stop
##


# STRHOME should have been set by env.sh above
if [ -z "$STRHOME" ]; then
    echo "STRHOME is not set."
    exit 1
fi
apppy="server/server_cli.py"
app="$STRHOME/$apppy"
data="$STRHOME/examples/data"
mkdir -p "$data"

# Function to start Flask servers
start_servers() {
    echo "Starting servers..."
    for port in "$@"
    do
        repo="$data/$port/repo"
        log="$data/$port/log"
        mkdir -p "$repo"
        python "$app" --port $port --repository "$repo" > "$log" 2>&1 &
        echo "Started Flask server on port $port with repository $repo"
    done
}

# Function to stop a specific server
stop_server() {
    echo "Stopping server on port $1..."
    pid=$(lsof -i :$1 -t)
    if [ -z "$pid" ]; then
        echo "No server found on port $1"
    else
        kill -9 $pid
        echo "Stopped server with PID $pid"
    fi
}

list_all() {
    echo "All instances of $app"

    # Print header
    printf "%-10s %-10s %-10s\n" "PID" "PORT" "TIME"

    # Find all PIDs for the given process name and extract relevant information
    echo "$app"
    ps auxw | grep "$app" | grep -v grep | awk '{
        pid = $2; 
        time = $10; 
        command = $11; 
        for (i = 12; i <= NF; i++) command = command " " $i; 
        port = "N/A"; 

        # Extract port if present in the command
        if (match(command, /--port[= ]+[0-9]+/)) {
            port = substr(command, RSTART+7, RLENGTH-7);
        }

        printf "%-10s %-10s %-10s\n", pid, port, time
    }'
}

stop_all() {
    echo "Killing all instances of $app..."

    # Find all PIDs for the given process name
    pids=$(ps auxw | grep "$app" | grep -v grep | awk '{print $2}')

    # Check if any PIDs were found
    if [ -z "$pids" ]; then
        echo "No processes found with the name $process_name."
        return
    fi

    # Kill the processes
    for pid in $pids
    do
        kill -9 $pid
        echo "Stopped process $pid"
    done
}


# Check command line arguments
if [ $# -eq 0 ]
then
    echo "No arguments provided. Usage: ./script.sh start|stop|kill [ports...]"
    exit 1
fi

# Main logic
case $1 in
    start)
        shift
        start_servers "$@"
        ;;
     stop)
        shift
        if [ $# -eq 0 ]; then
            stop_all
        else
            for port in "$@"
            do
                stop_server $port
            done
        fi
        ;;
    list)
        list_all
        ;;
    stop-all)
        stop_all
        ;;
    *)
        echo "Invalid command. Usage: ./script.sh start|stop|stop-all|kill [ports...]"
        exit 1
        ;;
esac

