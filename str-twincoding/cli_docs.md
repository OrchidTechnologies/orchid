
## Orchid Storage Project 

## CLI Docs

###`repo`
```
usage: storage repo [-h] [--path PATH] REPO_COMMAND ...

positional arguments:
  REPO_COMMAND        Repository path commands available.
    list              List files in the repository.
    file_path         Get the path to an encoded file.
    shard_path        Get the path to a shard of the encoded file.
    recovery_file_path
                      Get the path for a recovery file.
    tmp_file_path     Get the path for a temporary file.

options:
  -h, --help          show this help message and exit
  --path PATH         Path to the repository.
None
```
###`encode`
```
usage: storage encode [-h] --path PATH --output_path OUTPUT_PATH --k0 K0 --n0
                      N0 --k1 K1 --n1 N1 [--encoding0 ENCODING0]
                      [--encoding1 ENCODING1] [--overwrite]
                      [--key_path KEY_PATH]

options:
  -h, --help            show this help message and exit
  --path PATH           Path to the file to encode.
  --output_path OUTPUT_PATH
                        Output path for the encoded file.
  --k0 K0               k value for node type 0.
  --n0 N0               n value for node type 0.
  --k1 K1               k value for node type 1.
  --n1 N1               n value for node type 1.
  --encoding0 ENCODING0
                        Encoding for node type 0.
  --encoding1 ENCODING1
                        Encoding for node type 1.
  --overwrite           Overwrite existing files.
  --key_path KEY_PATH   Path to an OpenSSH compatible RSA encryption key.
None
```
###`decode`
```
usage: storage decode [-h] --encoded ENCODED --recovered RECOVERED
                      [--overwrite] [--key_path KEY_PATH]

options:
  -h, --help            show this help message and exit
  --encoded ENCODED     Path to the encoded file.
  --recovered RECOVERED
                        Path to the recovered file.
  --overwrite           Overwrite existing files.
  --key_path KEY_PATH   Path to an OpenSSH compatible RSA encryption key.
None
```
###`generate_recovery_file`
```
usage: storage generate_recovery_file [-h] --recover_node_type
                                      RECOVER_NODE_TYPE --recover_node_index
                                      RECOVER_NODE_INDEX
                                      [--recover_encoding RECOVER_ENCODING]
                                      --k K --n N --data_path DATA_PATH
                                      --output_path OUTPUT_PATH [--overwrite]

options:
  -h, --help            show this help message and exit
  --recover_node_type RECOVER_NODE_TYPE
                        Type of the recovering node.
  --recover_node_index RECOVER_NODE_INDEX
                        Index of the recovering node.
  --recover_encoding RECOVER_ENCODING
                        Encoding for the recovering node.
  --k K                 k value for the recovering node.
  --n N                 n value for the recovering node.
  --data_path DATA_PATH
                        Path to the source node data.
  --output_path OUTPUT_PATH
                        Path to the output recovery file.
  --overwrite           Overwrite existing files.
None
```
###`recover_node`
```
usage: storage recover_node [-h] --recover_node_type RECOVER_NODE_TYPE
                            --recover_node_index RECOVER_NODE_INDEX --k K --n
                            N [--encoding ENCODING] --files_dir FILES_DIR
                            --output_path OUTPUT_PATH [--overwrite]

options:
  -h, --help            show this help message and exit
  --recover_node_type RECOVER_NODE_TYPE
                        Type of the recovering node.
  --recover_node_index RECOVER_NODE_INDEX
                        Index of the recovering node.
  --k K                 k value for node type.
  --n N                 n value for node type.
  --encoding ENCODING   Encoding for node type.
  --files_dir FILES_DIR
                        Path to the recovery files.
  --output_path OUTPUT_PATH
                        Path to the recovered file.
  --overwrite           Overwrite existing files.
None
```
###`import`
```
usage: storage import [-h] [--repo REPO] [--k0 K0] [--n0 N0] [--k1 K1]
                      [--n1 N1] [--encoding0 ENCODING0]
                      [--encoding1 ENCODING1] [--overwrite]
                      [--key_path KEY_PATH]
                      path

positional arguments:
  path                  Path to the file to import.

options:
  -h, --help            show this help message and exit
  --repo REPO           Path to the repository.
  --k0 K0               k value for node type 0.
  --n0 N0               n value for node type 0.
  --k1 K1               k value for node type 1.
  --n1 N1               n value for node type 1.
  --encoding0 ENCODING0
                        Encoding for node type 0.
  --encoding1 ENCODING1
                        Encoding for node type 1.
  --overwrite           Overwrite existing files.
  --key_path KEY_PATH   Path to an OpenSSH compatible RSA encryption key.
None
```
###`list`
```
usage: storage list [-h] [--repo REPO]

options:
  -h, --help   show this help message and exit
  --repo REPO  Path to the repository.
None
```
###`push`
```
usage: storage push [-h] [--repo REPO] [--providers [PROVIDERS ...]]
                    [--validate] [--target_availability TARGET_AVAILABILITY]
                    [--dryrun] [--overwrite]
                    file

positional arguments:
  file                  Name of the file in the repository.

options:
  -h, --help            show this help message and exit
  --repo REPO           Path to the repository.
  --providers [PROVIDERS ...]
                        Optional list of provider names or urls for the push.
  --validate            After push, download and reconstruct the file.
  --target_availability TARGET_AVAILABILITY
                        Target availability for the file.
  --dryrun, -n          Show the plan without executing it.
  --overwrite           Overwrite files on the server.
None
```
###`request_recovery_file`
```
usage: storage request_recovery_file [-h] [--repo REPO] --provider PROVIDER
                                     [--overwrite] --recover_node_type
                                     RECOVER_NODE_TYPE --recover_node_index
                                     RECOVER_NODE_INDEX --source_node_index
                                     SOURCE_NODE_INDEX
                                     file

positional arguments:
  file                  Name of the file in the local and remote repositories.

options:
  -h, --help            show this help message and exit
  --repo REPO           Path to the repository.
  --provider PROVIDER   Provider from which to request the recovery file.
  --overwrite           Overwrite any local file.
  --recover_node_type RECOVER_NODE_TYPE
                        The node type for the shard being recovered.
  --recover_node_index RECOVER_NODE_INDEX
                        The node index for the shard being recovered.
  --source_node_index SOURCE_NODE_INDEX
                        The source node index desired to be used to generate
                        the recovery file.
None
```
###`request_repair`
```
usage: storage request_repair [-h] [--repo REPO] --to_provider TO_PROVIDER
                              --node_type NODE_TYPE --node_index NODE_INDEX
                              [--from_providers [FROM_PROVIDERS ...]]
                              [--dryrun] [--overwrite]
                              file

positional arguments:
  file                  Name of the file in the repository.

options:
  -h, --help            show this help message and exit
  --repo REPO           Path to the repository.
  --to_provider TO_PROVIDER
                        Provider to receive the repair request.
  --node_type NODE_TYPE
                        The node type for the shard being recovered.
  --node_index NODE_INDEX
                        The node index for the shard being recovered.
  --from_providers [FROM_PROVIDERS ...]
                        Optional list of provider names or urls for the
                        repair.
  --dryrun, -n          Show the plan without executing it.
  --overwrite           Overwrite files on the server.
None
```
###`request_delete_shard`
```
usage: storage request_delete_shard [-h] [--repo REPO] --provider PROVIDER
                                    --node_type NODE_TYPE --node_index
                                    NODE_INDEX
                                    file

positional arguments:
  file                  Name of the file in the local and remote repositories.

options:
  -h, --help            show this help message and exit
  --repo REPO           Path to the repository.
  --provider PROVIDER   Provider to receive the deletion request.
  --node_type NODE_TYPE
                        The node type of the shard to be deleted.
  --node_index NODE_INDEX
                        The node index of the shard to be deleted.
None
```

## Server Docs
```
Using default repository: /Users/pat/Desktop/OrchidProject/lab.orchid.com/orchid/str-twincoding/repository
usage: server_cli.py [-h] [--config CONFIG] [--interface INTERFACE]
                     [--port PORT] [--repository_dir REPOSITORY_DIR]
                     [--auth_key AUTH_KEY] [--debug]

Flask server with argument parsing

options:
  -h, --help            show this help message and exit
  --config CONFIG       server config file
  --interface INTERFACE
                        Interface the server listens on
  --port PORT           Port the server listens on
  --repository_dir REPOSITORY_DIR
                        Directory to store repository files
  --auth_key AUTH_KEY   Authentication key to validate requests
  --debug               Debug server
```

## Providers Docs
```
usage: providers_cli.py [-h] [--file FILE] COMMAND ...

Process command line arguments.

positional arguments:
  COMMAND      Sub-commands available.
    list       List providers
    add        Add providers
    clear      Clear the providers file

options:
  -h, --help   show this help message and exit
  --file FILE  Providers config file path
```

## Monitor Docs
```
usage: monitor_cli.py [-h] [--providers PROVIDERS] [--debug] [--update UPDATE]

Process command line arguments.

options:
  -h, --help            show this help message and exit
  --providers PROVIDERS
                        Providers config file path
  --debug               Show debug
  --update UPDATE       Update view with polling period seconds
```
