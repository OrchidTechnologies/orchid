import argparse
import asyncio
import os
from typing import List

from icecream import ic

from server.providers import Providers
from storage.file_list_table import FileListTable
from storage.file_upload import FileUpload
from storage.storage_model import NodeType, NodeType0, NodeType1, EncodedFileStatus
from storage.repository import Repository
from encoding.file_decoder import FileDecoder
from encoding.file_encoder import FileEncoder
from encoding.node_recovery_client import NodeRecoveryClient
from encoding.node_recovery_source import NodeRecoverySource
from storage.util import dump_docs_md
from tqdm import *


#
# Command line interface for Orchid Storage operations
#

def repo_list(args: argparse.Namespace):
    # can be invoked with either 'repo' or 'path' for the repo path
    path = getattr(args, 'repo', None) or getattr(args, 'path', None)
    repo = Repository(path=path) if path else Repository.default()
    files_status: list[EncodedFileStatus] = [repo.file_status(file) for file in repo.list()]
    if files_status:
        FileListTable(files_status).output()
    else:
        print("No files.")


def repo_file_path(args):
    print(Repository(path=args.path).file_dir_path(filename=args.file, expected=False))


def repo_shard_path(args):
    print(
        Repository(path=args.path).shard_path(filename=args.file, node_type=args.node_type, node_index=args.node_index,
                                              expected=False))


def repo_recovery_file_path(args):
    print(Repository(path=args.path).recovery_file_path(
        file=args.file,
        recover_node_type=args.recover_node_type,
        recover_node_index=args.recover_node_index,
        helper_node_index=args.helper_node_index,
        expected=False))


def repo_tmp_file_path(args):
    print(Repository(path=args.path).tmp_file_path(file=args.file))


def encode_file(args):
    FileEncoder(
        node_type0=NodeType0(k=args.k0, n=args.n0, encoding=args.encoding0),
        node_type1=NodeType1(k=args.k1, n=args.n1, encoding=args.encoding1),
        input_file=args.path,
        output_path=args.output_path,
        overwrite=args.overwrite
    ).encode()


# Import command: Similar to encode_file but defaults to repository paths
def import_file(args):
    # Default the file path
    filename = os.path.basename(args.path)
    repo = Repository(path=args.repo) if args.repo else Repository.default()

    output_path = repo.file_dir_path(filename=filename, expected=False)
    FileEncoder(
        node_type0=NodeType0(k=args.k0, n=args.n0, encoding=args.encoding0),
        node_type1=NodeType1(k=args.k1, n=args.n1, encoding=args.encoding1),
        input_file=args.path,
        output_path=output_path,
        overwrite=args.overwrite
    ).encode()


def push_file(args):
    assert not args.validate, "Validation not implemented yet."

    # context
    repo = Repository(path=args.repo) if args.repo else Repository.default()
    providers = Providers.default()

    # provider args
    filename = args.file
    providers_args: List[str] = args.providers  # optional explicit list of providers
    if providers_args:
        providers_list = providers.resolve_provider_names(providers_args)
    else:
        providers_list = None

    if not repo.file_exists(filename):
        print(f"File not found in repository: {filename}")
        return

    file_status: EncodedFileStatus = repo.file_status(filename)
    _progress_bars_map.clear()
    asyncio.run(FileUpload(repo, providers)
                .push(file_status, providers_list,
                      dryrun=args.dryrun, overwrite=args.overwrite, progress_callback=_progress_callback))


_progress_bars_map = {}


# index is the position of the progress bar in a multi-bar display
def _progress_callback(index: int, progress: int, total: int, bar_type: int):
    pbar = _progress_bars_map.get(index)
    if pbar is None:
        pbar = tqdm(
            desc=f'{index}',
            total=total,
            position=index,
            # leave=True,
            colour="cyan" if bar_type == 0 else "green"
        )
        _progress_bars_map[index] = pbar
    pbar.n = progress
    pbar.refresh()
    ...


def decode_file(args):
    FileDecoder.from_encoded_dir(
        path=args.encoded,
        output_path=args.recovered,
        overwrite=args.overwrite
    ).decode()


def generate_recovery_file(args):
    NodeRecoverySource(
        recover_node_type=NodeType(
            type=args.recover_node_type,
            k=args.k, n=args.n, encoding=args.recover_encoding),
        recover_node_index=args.recover_node_index,
        data_path=args.data_path,
        output_path=args.output_path,
        overwrite=args.overwrite
    ).generate()


def recover_node(args):
    NodeRecoveryClient(
        recovery_source_node_type=NodeType(
            # assume we are the opposite type of the node we are recovering
            type=0 if args.recover_node_type == 1 else 1,
            k=args.k, n=args.n, encoding=args.encoding),
        file_map=NodeRecoveryClient.map_files(
            files_dir=args.files_dir,
            recover_node_type=args.recover_node_type,
            recover_node_index=args.recover_node_index,
            k=args.k),
        output_path=args.output_path,
        overwrite=args.overwrite
    ).recover_node()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="storage", description="File encoding and decoding utility")
    subparsers = parser.add_subparsers(metavar='COMMAND', help="Sub-commands available.")

    # Repository sub-commands
    parser_repo = subparsers.add_parser('repo', help="Repository path related operations.")
    parser_repo.add_argument('--path', required=False, help="Path to the repository.")
    repo_subparsers = parser_repo.add_subparsers(metavar='REPO_COMMAND', help='Repository path commands available.')

    # Repository - list files
    parser_repo_list = repo_subparsers.add_parser('list', help="List files in the repository.")
    parser_repo_list.set_defaults(func=repo_list)

    # Repository - file_path command
    parser_file_path = repo_subparsers.add_parser('file_path', help="Get the path to an encoded file.")
    parser_file_path.add_argument('--file', required=True, help="The filename to get the path for.")
    parser_file_path.set_defaults(func=repo_file_path)

    # Repository - shard_path command
    parser_shard_path = repo_subparsers.add_parser('shard_path', help="Get the path to a shard of the encoded file.")
    parser_shard_path.add_argument('--file', required=True, help="The filename to get the shard path for.")
    parser_shard_path.add_argument('--node_type', type=int, required=True, help="The node type for the shard.")
    parser_shard_path.add_argument('--node_index', type=int, required=True, help="The node index for the shard.")
    parser_shard_path.set_defaults(func=repo_shard_path)

    # Repository - recovery_file_path command
    parser_recovery_file_path = repo_subparsers.add_parser('recovery_file_path',
                                                           help="Get the path for a recovery file.")
    parser_recovery_file_path.add_argument('--file', required=True, help="The filename to get the recovery path for.")
    parser_recovery_file_path.add_argument('--recover_node_type', type=int, required=True,
                                           help="The node type for recovery.")
    parser_recovery_file_path.add_argument('--recover_node_index', type=int, required=True,
                                           help="The node index for recovery.")
    parser_recovery_file_path.add_argument('--helper_node_index', type=int, required=True,
                                           help="The helper node index for recovery.")
    parser_recovery_file_path.set_defaults(func=repo_recovery_file_path)

    # Repository - tmp_file_path command
    parser_tmp_file_path = repo_subparsers.add_parser('tmp_file_path', help="Get the path for a temporary file.")
    parser_tmp_file_path.add_argument('--file', required=True, help="The filename to get the temporary path for.")
    parser_tmp_file_path.set_defaults(func=repo_tmp_file_path)

    # Encode - sub-commands
    parser_encode = subparsers.add_parser('encode', help="Encode a file.")
    parser_encode.add_argument('--path', required=True, help="Path to the file to encode.")
    parser_encode.add_argument('--output_path', required=True, help="Output path for the encoded file.")
    parser_encode.add_argument('--k0', type=int, required=True, help="k value for node type 0.")
    parser_encode.add_argument('--n0', type=int, required=True, help="n value for node type 0.")
    parser_encode.add_argument('--k1', type=int, required=True, help="k value for node type 1.")
    parser_encode.add_argument('--n1', type=int, required=True, help="n value for node type 1.")
    parser_encode.add_argument('--encoding0', default='reed_solomon', help="Encoding for node type 0.")
    parser_encode.add_argument('--encoding1', default='reed_solomon', help="Encoding for node type 1.")
    parser_encode.add_argument('--overwrite', action='store_true', help="Overwrite existing files.")
    parser_encode.set_defaults(func=encode_file)

    # Decode - sub-commands
    parser_decode = subparsers.add_parser('decode', help="Decode an encoded file.")
    parser_decode.add_argument('--encoded', required=True, help="Path to the encoded file.")
    parser_decode.add_argument('--recovered', required=True, help="Path to the recovered file.")
    parser_decode.add_argument('--overwrite', action='store_true', help="Overwrite existing files.")
    parser_decode.set_defaults(func=decode_file)

    # Recovery Generation - sub-commands
    parser_gen_rec = subparsers.add_parser('generate_recovery_file', help="Generate recovery files.")
    parser_gen_rec.add_argument('--recover_node_type', type=int, required=True, help="Type of the recovering node.")
    parser_gen_rec.add_argument('--recover_node_index', type=int, required=True, help="Index of the recovering node.")
    parser_gen_rec.add_argument('--recover_encoding', default='reed_solomon', help="Encoding for the recovering node.")
    parser_gen_rec.add_argument('--k', type=int, required=True, help="k value for the recovering node.")
    parser_gen_rec.add_argument('--n', type=int, required=True, help="n value for the recovering node.")
    parser_gen_rec.add_argument('--data_path', required=True, help="Path to the source node data.")
    parser_gen_rec.add_argument('--output_path', required=True, help="Path to the output recovery file.")
    parser_gen_rec.add_argument('--overwrite', action='store_true', help="Overwrite existing files.")
    parser_gen_rec.set_defaults(func=generate_recovery_file)

    # Node Recovery
    parser_rec_node = subparsers.add_parser('recover_node', help="Recover a node from recovery files.")
    parser_rec_node.add_argument('--recover_node_type', type=int, required=True, help="Type of the recovering node.")
    parser_rec_node.add_argument('--recover_node_index', type=int, required=True, help="Index of the recovering node.")
    parser_rec_node.add_argument('--k', type=int, required=True, help="k value for node type.")
    parser_rec_node.add_argument('--n', type=int, required=True, help="n value for node type.")
    parser_rec_node.add_argument('--encoding', default='reed_solomon', help="Encoding for node type.")
    parser_rec_node.add_argument('--files_dir', required=True, help="Path to the recovery files.")
    parser_rec_node.add_argument('--output_path', required=True, help="Path to the recovered file.")
    parser_rec_node.add_argument('--overwrite', action='store_true', help="Overwrite existing files.")
    parser_rec_node.set_defaults(func=recover_node)

    # Import: Like Encode but using the default repo paths and encoding
    parser_import = subparsers.add_parser('import', help="Import file using default repo and encoding.")
    parser_import.add_argument('--repo', required=False, help="Path to the repository.")
    parser_import.add_argument('--k0', type=int, default="3", help="k value for node type 0.")
    parser_import.add_argument('--n0', type=int, default="5", help="n value for node type 0.")
    parser_import.add_argument('--k1', type=int, default="3", help="k value for node type 1.")
    parser_import.add_argument('--n1', type=int, default="5", help="n value for node type 1.")
    parser_import.add_argument('--encoding0', default='reed_solomon', help="Encoding for node type 0.")
    parser_import.add_argument('--encoding1', default='reed_solomon', help="Encoding for node type 1.")
    parser_import.add_argument('--overwrite', action='store_true', help="Overwrite existing files.")
    parser_import.add_argument('path', help="Path to the file to import.")  # Positional argument
    parser_import.set_defaults(func=import_file)

    # List: an alias for `repo list`
    parser_import = subparsers.add_parser('list', help="List files in the repository.")
    parser_import.add_argument('--repo', required=False, help="Path to the repository.")
    parser_import.set_defaults(func=repo_list)

    # Push: Send a file in the repository to one or more providers
    parser_push = subparsers.add_parser('push', help="Send a file in the repository to one or more providers.")
    parser_push.add_argument('--repo', required=False, help="Path to the repository.")
    parser_push.add_argument('--providers', required=False, nargs='*',
                             help="Optional list of provider names or urls for the push.")
    parser_push.add_argument('--validate', action='store_true', help="After push, download and reconstruct the file.")
    parser_push.add_argument('--target_availability', type=float, default=1.0, help="Target availability for the file.")
    parser_push.add_argument('--dryrun', '-n', action='store_true', help="Show the plan without executing it.")
    parser_push.add_argument('--overwrite', action='store_true', help="Overwrite files on the server.")
    parser_push.add_argument('file', help="Name of the file in the repository.")
    parser_push.set_defaults(func=push_file)

    # Dump all help for docs
    parser_docs = subparsers.add_parser('docs')
    parser_docs.set_defaults(func=lambda args: dump_docs_md(args, subparsers))

    args = parser.parse_args()
    if hasattr(args, 'func'):
        args.func(args)
    else:
        parser.print_help()
