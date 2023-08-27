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
# column of the encoded matrices is then assigned to a node of its
# respective type, resulting in two distinct sets of n nodes.
#
# message:
# The message to be encoded. This is an array of k^2 symbols length.
#
# G0, G1:
# The supplied pair of coding schemes can be any k of n linear codes (e.g.
# Reed-Solomon). They may be the same or different.
#
# Return:
# This method returns the two lists of n column vectors to be stored at the
# respective node types.
#
# The original paper:
# https://www.cs.cmu.edu/~nihars/publications/repairAnyStorageCode_ISIT2011.pdf
#
def twin_code(message: np.array, k: int, n: int, G0: np.matrix, G1: np.matrix):
    M0 = message.reshape((k, k))  # Reshape the message into k x k matrix
    M1 = M0.T  # M1 is the transpose of M0

    # Encode using G0 and G1
    encoded_type_0 = np.dot(M0, G0)
    encoded_type_1 = np.dot(M1, G1)

    # Nodes store k symbols corresponding to a column of the (k × n) encoded
    # matrix of their type.
    type_0_nodes = [encoded_type_0[:, i] for i in range(n)]
    type_1_nodes = [encoded_type_1[:, i] for i in range(n)]

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


#
# Tests.
#
if __name__ == "__main__":
    # Set up the code schemes
    GF = galois.GF(2 ** 8)
    k, n = 3, 5  # Note that n must be less than the field size

    G0 = rs_generator_matrix(GF, k, n)
    G1 = rs_generator_matrix(GF, k, n)

    message = GF([1, 2, 3, 5, 8, 13, 21, 34, 55])  # k^2 = 9 symbols in GF(2^8)
    print("message:", message)

    # Twin code the message
    nodes0, nodes1 = twin_code(message, k, n, G0, G1)

    #
    # Simulate regular data collection: Gather data from any k nodes and
    # decode it.
    #
    print("\nSimulate data collection:")
    collect_from_node_type = 0

    nodes = nodes0 if collect_from_node_type == 0 else nodes1
    G = G0 if collect_from_node_type == 0 else G1

    # Download k columns from the set of nodes.
    cols = nodes[:k].T
    # Take the corresponding k columns of their generator matrix and invert it
    g = G[:, 0:k]
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
    print("\nSimulate node recovery")
    failed_node_number = 1
    failed_node_type = 0

    # The k symbols of the lost node correspond to the i'th column of the
    # encoded matrix of its type, where i is the failed node number.
    # We contact k nodes of the opposite type and ask for their help.
    my_nodes, helper_nodes = (nodes0, nodes1) if failed_node_type == 0 else (
        nodes1, nodes0)
    nodes_to_ask = helper_nodes[:k]

    # Use the encoding vector for the failed node, which is the i'th column
    # of the generator matrix of its type.
    G = G0 if failed_node_type == 0 else G1
    encoding_vector = G[:, failed_node_number]

    # Each helper node calculates the inner product of its k encoded symbols
    # and the encoding vector of the failed node.
    node_responses = GF(
        [np.dot(encoding_vector, GF(node)) for node in nodes_to_ask])
    print("node_responses:", node_responses)

    # We now treat the node responses as a vector and use our inverted
    # generator matrix to recover the missing column.
    g = G[:, 0:k]
    ginv = np.linalg.inv(g)
    recovered = node_responses @ ginv
    # TODO: concise explanation of why this works.

    # Print the results
    original = my_nodes[failed_node_number]
    print("original:", original)
    print("recovered:", recovered)
    passed = (recovered == original).all()
    print('Total symbols transferred = ', np.size(node_responses))
    print("Test passed." if passed else "Test failed.")

