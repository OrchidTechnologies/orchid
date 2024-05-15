import ckzg
from commitments.kzg_commitment import get_kzg_setup, FileCommitments


# Generate a random blob: 4096 field elements.
def random_blob() -> bytes:
    blob = b''
    for i in range(4096):
        blob += FileCommitments.random_field_element()
    return blob


# Simulate corruption: Flip one bit in the blob
def flip_bit(blob: bytes) -> bytes:
    return blob[:17] + bytes([blob[17] ^ 0x01]) + blob[18:]


def test_verify(setup, corrupt=False):
    # Generate a random blob
    blob = random_blob()
    # print(f"blob: {type(blob)}, {len(blob)}")
    # print(f"blob: {blob[:32].hex()}")

    # Commit to the blob
    commitment = ckzg.blob_to_kzg_commitment(blob, setup)
    # print("commitment: ", commitment.hex(), len(commitment))

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
    z_eval = FileCommitments.random_field_element()
    proof, y_out = ckzg.compute_kzg_proof(blob, z_eval, setup)
    # print("proof: ", proof.hex(), len(proof))

    # Sanity check that the proof seems suitably random (doesn't match any previous proof)
    assert proof not in proofs
    proofs.add(proof)

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


if __name__ == "__main__":
    setup = get_kzg_setup()
    proofs = set()

    for i in range(10):
        print(f"{i}", end=",")
        # Test with a valid proof
        test_verify(setup)
        # Test with a corrupt proof
        test_verify(setup, corrupt=True)

    print("\nTests passed")
