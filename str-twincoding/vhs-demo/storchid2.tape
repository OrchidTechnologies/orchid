
Output storchid2.gif
Output storchid2.mp4

Set FontSize 18
Set Width 1200
Set Height 720
Set TypingSpeed 0.05
#Set LineHeight 1.8
#Set Margin 0
Set Padding 12

# Playback seems accelerated for some reason?
Set PlaybackSpeed 0.5

#Set Theme { "name": "Whimsy", "black": "#535178", "red": "#ef6487", "green": "#5eca89", "yellow": "#fdd877", "blue": "#65aef7", "magenta": "#aa7ff0", "cyan": "#43c1be", "white": "#ffffff", "brightBlack": "#535178", "brightRed": "#ef6487", "brightGreen": "#5eca89", "brightYellow": "#fdd877", "brightBlue": "#65aef7", "brightMagenta": "#aa7ff0", "brightCyan": "#43c1be", "brightWhite": "#ffffff", "background": "#29283b", "foreground": "#b3b0d6", "selection": "#3d3c58", "cursor": "#b3b0d6" }

# Set Padding 0
# Set WindowBar Colorful

# Setup
Hide
Type "cd $STRHOME"
Enter
# Doesn't work here?
Type "export PS1='> '"
Enter
Type "examples/test-cluster.sh stop"
Enter
Type "./clean.sh"
Enter
Type "clear"
Enter
Show


Sleep 2s
Set TypingSpeed 0.05
Type "# Let's use Orchid Storage!"
Enter 2
Sleep 3
Type "# Generate a test file"
Enter
Set TypingSpeed 0.025
Type "dd if=/dev/urandom of='foo_file.dat' bs=1K count=1 status=none"
Enter 2
Sleep 3s

Set TypingSpeed 0.05
Type "# Import a file into the default local repository with default encoding"
Enter
Set TypingSpeed 0.03
Type "storage.sh import foo_file.dat"
Enter 2
Sleep 5s

Set TypingSpeed 0.05
Type "# List the repository"
Enter 
Set TypingSpeed 0.03
Type "storage.sh repo list"
Enter 2
Sleep 5s

Set TypingSpeed 0.05
Type "# Start a test provider server cluster"
Enter
Set TypingSpeed 0.025
Type "examples/test-cluster.sh start 5001 5002 5003 5004 5005"
Enter 2
Sleep 4s

Set TypingSpeed 0.05
Type "# Confirm that the test servers are running"
Enter
Set TypingSpeed 0.03
Type "examples/test-cluster.sh list"
Enter 2
Sleep 4s

Set TypingSpeed 0.025
Type "# 'Discover' these providers, adding them to our known provider list"
Enter
Type "# (This will normally be done via the directory service and performed at file push time.)"
Enter
Set TypingSpeed 0.03
Type "providers.sh add 5001 5002 5003 5004 5005"
Enter 2
Sleep 4s

Set TypingSpeed 0.05
Type "# List the known providers"
Enter
Set TypingSpeed 0.03
Type "providers.sh list"
Enter 2
Sleep 5s

# Monitor
Set TypingSpeed 0.05
Type "# Check the cluster status"
Enter
Set TypingSpeed 0.03
Type "monitor.sh"
Enter 2
Sleep 5s

Set TypingSpeed 0.05
Type "# Push the file by name"
Enter
Set TypingSpeed 0.03
Type "storage.sh push foo_file.dat"
Enter 2
Sleep 6s

# Monitor
Set TypingSpeed 0.05
Type "# Check the cluster status"
Enter
Set TypingSpeed 0.03
Type "monitor.sh"
Enter 2
Sleep 5s

Set TypingSpeed 0.05
Type "# Delete a shard from one of the providers"
Enter
Set TypingSpeed 0.03
Type "storage.sh request_delete_shard --provider 5001 foo_file.dat --node_type 0 --node_index 0"
Enter 2
Sleep 4s

# Monitor
Set TypingSpeed 0.05
Type "# Check the cluster status"
Enter
Set TypingSpeed 0.03
Type "monitor.sh"
Enter 2
Set TypingSpeed 0.05
Type "# (Observe the availability is reduced as a unique shard is lost)"
Enter 2
Sleep 6s

Set TypingSpeed 0.05
Type "# Request that the provider rebuild the lost node from specified other nodes in the cluster."
Enter
Set TypingSpeed 0.03
Type "storage.sh request_repair --to_provider 5001 foo_file.dat --node_type 0 --node_index 0 --from_providers 5002 5003 5004"
Enter
Sleep 4s

# Monitor
Set TypingSpeed 0.05
Type "# Check the cluster status"
Enter
Set TypingSpeed 0.03
Type "monitor.sh"
Enter 2
Sleep 5s
Set TypingSpeed 0.05
Type "# (Observe the availability has returned to the original value)"
Enter 2

Sleep 10s

# Shut down the servers
#examples/test-cluster.sh stop


