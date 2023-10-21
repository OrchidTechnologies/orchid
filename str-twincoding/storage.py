import argparse
from config import NodeType, NodeType0, NodeType1
from file_decoder import FileDecoder
from file_encoder import FileEncoder
from node_recovery_client import NodeRecoveryClient
from node_recovery_source import NodeRecoverySource


#
# Command line interface for node encoding and recovery.
#

def encode_file(args):
    FileEncoder(
        node_type0=NodeType0(k=args.k0, n=args.n0, encoding=args.encoding0),
        node_type1=NodeType1(k=args.k1, n=args.n1, encoding=args.encoding1),
        path=args.path,
        overwrite=args.overwrite
    ).encode()


def decode_file(args):
    FileDecoder.from_encoded_dir(
        path=args.encoded,
        output_path=args.recovered,
        overwrite=args.overwrite
    ).decode()


def generate_recovery_file(args):
    NodeRecoverySource(
        recover_node_type=NodeType(k=args.k, n=args.n, encoding=args.recover_encoding),
        recover_node_index=args.recover_node_index,
        data_path=args.data_path,
        output_path=args.output_path,
        overwrite=args.overwrite
    ).generate()


def recover_node(args):
    NodeRecoveryClient(
        recovery_source_node_type=NodeType(k=args.k, n=args.n, encoding=args.encoding),
        file_map=NodeRecoveryClient.map_files(files_dir=args.files_dir, k=args.k),
        output_path=args.output_path,
        overwrite=args.overwrite
    ).recover_node()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="File encoding and decoding utility")
    subparsers = parser.add_subparsers(metavar='COMMAND', help="Sub-commands available.")

    # Encoding
    parser_encode = subparsers.add_parser('encode', help="Encode a file.")
    parser_encode.add_argument('--path', required=True, help="Path to the file to encode.")
    parser_encode.add_argument('--k0', type=int, required=True, help="k value for node type 0.")
    parser_encode.add_argument('--n0', type=int, required=True, help="n value for node type 0.")
    parser_encode.add_argument('--k1', type=int, required=True, help="k value for node type 1.")
    parser_encode.add_argument('--n1', type=int, required=True, help="n value for node type 1.")
    parser_encode.add_argument('--encoding0', default='reed_solomon', help="Encoding for node type 0.")
    parser_encode.add_argument('--encoding1', default='reed_solomon', help="Encoding for node type 1.")
    parser_encode.add_argument('--overwrite', action='store_true', help="Overwrite existing files.")
    parser_encode.set_defaults(func=encode_file)

    # Decoding
    parser_decode = subparsers.add_parser('decode', help="Decode an encoded file.")
    parser_decode.add_argument('--encoded', required=True, help="Path to the encoded file.")
    parser_decode.add_argument('--recovered', required=True, help="Path to the recovered file.")
    parser_decode.add_argument('--overwrite', action='store_true', help="Overwrite existing files.")
    parser_decode.set_defaults(func=decode_file)

    # Recovery Generation
    parser_gen_rec = subparsers.add_parser('generate_recovery_file', help="Generate recovery files.")
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
    parser_rec_node.add_argument('--k', type=int, required=True, help="k value for node type.")
    parser_rec_node.add_argument('--n', type=int, required=True, help="n value for node type.")
    parser_rec_node.add_argument('--encoding', default='reed_solomon', help="Encoding for node type.")
    parser_rec_node.add_argument('--files_dir', required=True, help="Path to the recovery files.")
    parser_rec_node.add_argument('--output_path', required=True, help="Path to the recovered file.")
    parser_rec_node.add_argument('--overwrite', action='store_true', help="Overwrite existing files.")
    parser_rec_node.set_defaults(func=recover_node)

    args = parser.parse_args()
    if hasattr(args, 'func'):
        args.func(args)
    else:
        parser.print_help()
