from twin_coding import Code
import numpy as np
import torch


# WIP: This is a sketch of what it would look like to perform encoding in batches on the GPU
# with pytorch. `messages` would be a batch_size x k^2 array of symbols.
#
# WIP: This won't work as-is because we are using a non-prime Galois field and the field
# operations are not simply modulus operations which could be deferred until after the matrix
# multiplication.
#
def twin_code_batch(messages: np.ndarray, C0: 'Code', C1: 'Code') -> (np.ndarray, np.ndarray):
    assert C0.k == C1.k
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

    batch_size = messages.shape[0]

    # Reshape the messages into batch_size x k x k
    M0 = torch.tensor(messages.reshape((batch_size, C0.k, C0.k))).to(device)
    M1 = torch.einsum('bik->bki', M0)

    # Encode messages using the respective coding schemes
    E0 = torch.einsum('bik,kj->bij', M0, C0.G)  # size batch_size x k x C0.n
    E1 = torch.einsum('bik,kj->bij', M1, C1.G)  # size batch_size x k x C1.n

    # Nodes store k symbols corresponding to a column of the (k x n) encoded matrix of their type
    type_0_nodes = np.transpose(E0, (2, 0, 1))  # size C0.n x batch_size x k
    type_1_nodes = np.transpose(E1, (2, 0, 1))  # size C1.n x batch_size x k

    return type_0_nodes, type_1_nodes
