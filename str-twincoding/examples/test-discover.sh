#!/bin/bash
#
# {
#    "providers": [
#        { "name": "5001", "url": "http://localhost:5001" },
#        { "name": "5002", "url": "http://localhost:5002" },
#        { "name": "5003", "url": "http://localhost:5003" }
#    ]
# }
#
source "$(dirname "$0")/../env.sh"
providers_file="$STRHOME/providers.jsonc"

# if no args, print help
if [ $# -eq 0 ]; then
    echo "Usage: $0 <port> <port> ..."
    exit 1
fi

# validate that all args are numbers
for port in "$@"
do
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "Invalid port: $port"
        exit 1
    fi
done

# if the file exists, bail
if [ -f "$providers_file" ]; then
    echo "File exists: $providers_file"
    exit 1
fi

# Generate the file
echo '{' > "$providers_file"
echo '   "providers": [' >> "$providers_file"
for port in "$@"
do
    echo '       { "name": "'"$port"'", "url": "http://localhost:'"$port"'" },' >> "$providers_file"
done
# jsonc is tolerant of trailing commas
#sed -i '$ s/,$//' "$providers_file"
echo '   ]' >> "$providers_file"
echo '}' >> "$providers_file"

echo "Generated file: $providers_file"
