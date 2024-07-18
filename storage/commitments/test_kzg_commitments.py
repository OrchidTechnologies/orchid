import ckzg

from commitments.blst_ctypes import object_as_kzg_settings, bytes_from_fr
from commitments.kzg_commitment import get_kzg_setup, FileCommitments


# Generate a random blob: 4096 field elements.
def random_blob() -> bytes:
    return b''.join(FileCommitments.random_field_element() for _ in range(4096))


# Simulate corruption: Flip one bit in the blob
def flip_bit(blob: bytes) -> bytes:
    return blob[:17] + bytes([blob[17] ^ 0x01]) + blob[18:]


def test_verify(setup, corrupt=False):
    # Generate a random blob
    blob = random_blob()
    # print(f"blob: {blob[:32].hex()}")

    # Commit to the blob
    commitment = ckzg.blob_to_kzg_commitment(blob, setup)
    # print(f"Commitment: {commitment.hex()[:16]}..., {len(commitment)} bytes")

    # Optionally flip a bit in the blob before the proof is generated
    # (simulate trying to prove availability with a bad blob)
    if corrupt:
        blob = flip_bit(blob)

    # Compute KZG proof for polynomial in Lagrange form at position z.
    # @param[out] proof_out The combined proof as a single G1 element
    # @param[out] y_out     The evaluation of the polynomial at the evaluation point z
    # @param[in]  blob      The blob (polynomial) to generate a proof for
    # @param[in]  z         The generator z-value for the evaluation points
    # @param[in]  s         The trusted setup
    # Check a random field element
    z_eval = FileCommitments.random_field_element()
    proof, y_out = ckzg.compute_kzg_proof(blob, z_eval, setup)
    # print(f"Proof: {proof.hex()[:16]}..., y_out: {y_out.hex()[:16]}..., len: {len(proof)}")

    # Sanity check that the proof seems suitably random (doesn't match any previous proof)
    assert proof not in proofs
    proofs.add(proof)

    # Sanity check a proof that corresponds to a known field element
    index = 3
    z_eval = bytes_from_fr(roots_of_unity[index])
    proof, y_out = ckzg.compute_kzg_proof(blob, z_eval, setup)
    expected_y_out = blob[index * 32:(index + 1) * 32]  # Extract the corresponding element from the blob
    assert y_out == expected_y_out

    # Verify a KZG proof claiming that `p(z) == y`.
    # @param[out] ok         True if the proofs are valid, otherwise false
    # @param[in]  commitment The KZG commitment corresponding to poly p(x)
    # @param[in]  z          The evaluation point
    # @param[in]  y          The claimed evaluation result
    # @param[in]  kzg_proof  The KZG proof
    # @param[in]  s          The trusted setup
    #
    # print("commitment: ", commitment.hex(), len(commitment))
    # print("proof: ", proof.hex(), len(proof))
    # print("y_out: ", y_out.hex(), len(y_out))
    ok = ckzg.verify_kzg_proof(commitment, z_eval, y_out, proof, setup)

    if ok and corrupt:
        print("Error, proof should be invalid!")
    if not ok and not corrupt:
        print("Error, proof should be valid!")
        # print("blob: ", blob.hex())


def test_roots_of_unity():
    # Check some roots of unity
    assert (bytes_from_fr(roots_of_unity[0]).hex() ==
            '0000000000000000000000000000000000000000000000000000000000000001')
    assert (bytes_from_fr(roots_of_unity[1]).hex() ==
            '73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000000')
    assert (bytes_from_fr(roots_of_unity[3]).hex() ==
            '73eda753299d7d47a5e80b39939ed33467baa40089fb5bfefffeffff00000001')
    print("Roots of unity look correct")


if __name__ == "__main__":
    setup = get_kzg_setup()
    roots_of_unity = object_as_kzg_settings(setup).roots_of_unity
    proofs = set()

    for i in range(3):
        print(f"{i}", end=",")
        # Test with a valid proof
        test_verify(setup)
        # Test with a corrupt proof
        test_verify(setup, corrupt=True)

    test_roots_of_unity()

    print("\nTests passed")
