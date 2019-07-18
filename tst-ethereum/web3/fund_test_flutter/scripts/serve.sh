#!/bin/sh

# Run a web server bound to the local ip on the primary interface.
# Note: 'php -S localhost:8080' would suffice for desktop browser testing.
local_ip=$(ipconfig getifaddr $(route -n get 0.0.0.0 2>/dev/null | awk '/interface: / {print $2}'))
cd $(dirname "$0")/../build/
php -S "${local_ip}:8080"
