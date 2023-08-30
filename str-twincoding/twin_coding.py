import numpy as np
import galois


#
# Twin Coding is a hybrid encoding scheme that works with any two linear
# coding schemes and combines them to achieve a space-bandwidth tradeoff,
# minimizing the amount of data that must be transferred between storage
# nodes in order to recover a lost shard of data.
#
# Two copies of the data are encoded, one using each of the sub-schemes,
# and then split among corresponding sets of nodes. Unlike a traditional k of n
# coding scheme in which the reconstruction of a single lost shard requires
# gathering the full data from k nodes, Twin Coding allows nodes to cooperate
# by performing a computation and transferring a smaller amount of data,
# reducing the total transfer to exactly the size of the lost shard.

# Specifically, a message of k^2 symbols in length is broken encoded into
# k-length shards. Utilizing twin coding the recovery of a shard requires
# downloading only a single (calculated) symbol from any k nodes of the
# alternate node type.  This is in contrast to the k^2 symbols that would
# be required with a single coding scheme.
#
# The message is reshaped to a k x k matrix and encoded using the supplied
# generator matrices of the code schemes into two, k x n, matrices. Each
# column of the encoded matrices is then assigned to a node of its respective
# type, resulting in two distinct sets of n nodes.
#
# message:
# The message to be encoded. This is an array of k^2 symbols length.
#
# C0, C1:
# The supplied pair of coding schemes can be any k of n linear codes (e.g.
# Reed-Solomon). They may be the same or different schemes. They should
# share k but may have different encoded lengths n.
#
# Return:
# This method returns the two lists of n column vectors to be stored at the
# respective node types. The two node sets will be different sizes if the codes
# have different n values.
#
# The original paper:
# https://www.cs.cmu.edu/~nihars/publications/repairAnyStorageCode_ISIT2011.pdf
#
def twin_code(message: np.array, C0: 'Code', C1: 'Code'):
    assert C0.k == C1.k

    # Reshape the message into k x k matrix
    M0 = message.reshape((C0.k, C0.k))
    M1 = M0.T  # M1 is the transpose of M0

    # Encode the messages using the respective coding schemes
    E0 = M0 @ C0.G  # size k x C0.n
    E1 = M1 @ C1.G  # size k x C1.n

    # Nodes store k symbols corresponding to a column of the (k × n) encoded
    # matrix of their type.
    type_0_nodes = [E0[:, i] for i in range(C0.n)]
    type_1_nodes = [E1[:, i] for i in range(C1.n)]

    return np.array(type_0_nodes), np.array(type_1_nodes)


#
# Construct a Reed Solomon generator matrix for consecutive evaluation points
# of the specified Galois field. This is a k x n matrix where each column
# corresponds to an evaluation point and holds consecutive powers of
# that value (e.g. x^0, x^1, x^2, x^3, ...).  Multiplying on the left by a
# row vector of k data symbols produces a polynomial of degree k-1 having
# coefficients of the k data points multiplying consecutive powers of the
# evaluation point, comprising an evaluation of the polynomial at that point.
# (e.g. k0 + k1*x + k2*x^2 + k3*x^3...) The end result is a row vector of n
# symbols, each corresponding to an evaluation of the polynomial at its
# column's eval point.
#
# Note: This is the same as the transpose of the Vandermonde matrix. However,
# we cannot use np.vander() here because the galois package does not override
# it to operate on GF elements.
#
# More information:
# https://en.wikipedia.org/wiki/Reed%E2%80%93Solomon_error_correction
#
def rs_generator_matrix(GF: galois.GF, k: int, n: int):
    eval_points = GF.elements[1:n + 1]  # n consecutive elements [1, 2, 3, 4, 5]
    matrix = GF(np.zeros(shape=(k, n), dtype=int))
    for row in range(k):
        for col in range(n):
            matrix[row, col] = eval_points[col] ** row
    return matrix


# The parameters of a linear coding scheme
class Code:
    def __init__(self, GF: galois.GF, k: int, n: int, G: np.matrix):
        self.GF = GF  # The symbol space
        self.k = k  # Dimension of message
        self.n = n  # Dimension of the coded message
        self.G = G  # Generator matrix


#
# Tests.
#
if __name__ == "__main__":
    # The symbol space
    GF = galois.GF(2 ** 8)

    # The two coding schemes.
    k = 3  # The schemes share k but may have different encoded lengths n
    C0 = Code(k=k, n=5, GF=GF, G=rs_generator_matrix(GF, k=k, n=5))
    C1 = Code(k=k, n=7, GF=GF, G=rs_generator_matrix(GF, k=k, n=7))

    message = GF([1, 2, 3, 5, 8, 13, 21, 34, 55])  # k^2 = 9 symbols in GF(2^8)
    print("message:", message)

    # Twin code the message
    nodes0, nodes1 = twin_code(message, C0, C1)
    print(f"{len(nodes0)} type 0 nodes\n{len(nodes1)} type 1 nodes")

    #
    # Simulate regular data collection: Gather data from any k nodes and
    # decode it.
    #
    print("\nSimulate data collection:")
    collect_from_node_type = 0

    nodes = nodes0 if collect_from_node_type == 0 else nodes1
    G_mine = C0.G if collect_from_node_type == 0 else C1.G

    # Download k columns from the set of nodes.
    cols = nodes[:k].T
    # Take the corresponding k columns of their generator matrix and invert it
    g = G_mine[:, 0:k]
    ginv = np.linalg.inv(g)

    # Use it to decode the data
    decoded = GF(cols) @ ginv
    # (This works because if E = M * G, then M = E * Ginv)
    print("decoded:", decoded.reshape(-1))

    # Print the results
    passed = (decoded.reshape(-1) == message).all()
    print('Total symbols transferred = ', np.size(cols))
    print("Test passed." if passed else "Test failed.")

    #
    # Simulate node recovery: Cooperate with k nodes of the opposite type to
    # recover a lost node with minimal data transfer.
    #
    print("\nSimulate node recovery:")
    failed_node_number = 1
    failed_node_type = 0

    # The k symbols of the lost node correspond to the i'th column of the
    # encoded matrix of its type, where i is the failed node number.
    # We contact k nodes of the opposite type and ask for their help.
    my_nodes, helper_nodes = (nodes0, nodes1) if failed_node_type == 0 else (
        nodes1, nodes0)

    # Pick k random helper nodes to ask
    nodes_to_ask = np.random.choice(helper_nodes.shape[0], k, replace=False)
    print("Picking helper nodes:", nodes_to_ask)

    # Use the encoding vector for the failed node, which is the i'th column
    # of the generator matrix of its type.
    G_mine, G_other = (C0.G, C1.G) if failed_node_type == 0 else (C1.G, C0.G)
    encoding_vector = G_mine[:, failed_node_number]

    # Each helper node calculates the inner product of its k encoded symbols
    # and the encoding vector of the failed node.
    node_responses = GF([encoding_vector @ node_vector
                         for node_vector in GF(helper_nodes[nodes_to_ask])])
    print("node_responses:", node_responses)

    # Now treat the responses as a vector and perform erasure decoding using the
    # helper node type's encoding matrix.
    g = G_other[:, nodes_to_ask]
    ginv = np.linalg.inv(g)
    recovered = node_responses @ ginv
    # TODO: concise explanation of why this works.

    # Print the results
    original = my_nodes[failed_node_number]
    print("Original:", original)
    print("Recovered:", recovered)
    passed = (recovered == original).all()
    print('Total symbols transferred = ', np.size(node_responses))
    print("Test passed." if passed else "Test failed.")

    """
    message: [ 1  2  3  5  8 13 21 34 55]
    5 type 0 nodes
    7 type 1 nodes

    Simulate data collection:
    decoded: [ 1  2  3  5  8 13 21 34 55]
    Total symbols transferred =  9
    Test passed.

    Simulate node recovery:
    Picking helper nodes: [3 1 5]
    node_responses: [181  69 249]
    Original: [  9  33 141]
    Recovered: [  9  33 141]
    Total symbols transferred =  3
    Test passed.
    """
