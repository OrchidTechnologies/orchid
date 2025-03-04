
// 
// Data Types
//

Field        // field-sized value
Point        // point-sized value
TimePeriod   // Ethereum block number
TokenValue   // funds token value
Address      // Ethereum address
Signature    // signature components
Int          // integer value

// A polynomial opening / inclusion proof. (Used with a commitment: Point).
struct Opening {
    proof: Point         // Proof offered
    z_eval: Field        // z index of the evaluation
    y_eval: Field        // y output value of the evaluatiion
}

// A rate certificate
struct RateCertificate {
    cohort_id: Int                   // An identifier that groups the RCs for a given client.
    block_root_id: Point             // The block commitment to which the RC refers (commitment to poly r)
    commitment_payment: TokenValue   // Amount paid per commitment
    client: Address                  // The client (block owner) address
    signature: Signature             // The client (block owner) signature

    // TODO: Bond size discussion: 
    // 1) Each periodic commitment is accompanied by a provider bond which is forfeit if the commitment is found to 
    // be invalid at settlement time.
    // 2) Ideally the bond size will be specifed by the client (commensurate with the risk), however this complicates
    // contemporaneous monitoring because bonds will be posted in aggregate for the provider for the period and
    // the cohort must therefore have knowledge of the individual bond sizes to determine the sum.  In our current
    // scheme rate certificates are available on-chain so this is possible, however it has been noted that this introduces
    // an n-squared component to monitoring.
    
    // TODO: Bond implementation discussion:
    // An efficient way to handle the bonds might be to integrate them with the provider's stake, as in the orchid lottery.
    // i.e. the bond would simply escrow some portion of the provider's stake rather than requiring new funds.

    // Provider per-commitment bond size
    bond_size: TokenValue 

    // Designate the provider responsible for this block.
    provider: Address
}

// Periodic commitment to beacon-selected subblocks and hosted client block ids.
struct PeriodicCommitment {
    p: Point    // commitment to the beacon-selected subblock
    q: Point    // commitment to the client block ids

    // The provider bond amount posted with the commitment
    // (The value being supplied to the post_periodic_commitment function along with this data)
    bond_amount: TokenValue  
}

// A provider-generated request to settle for a period
struct SettlementRequest {
    period: TimePeriod          // The period to settle
    block_root_id: Point        // The original r poly commitment to the block.
    r_opening: Opening          // Opening of r (original block commitment)
    p_opening: Opening          // Opening of p (periodic subblock commitment)
    q_opening: Opening          // Opening of q (periodic "client" commitment)
}


//
// The Settlement Contract 
//

// Post a new rate certificate
function post_rate_certificate(rate_certificate: RateCertificate) -> void {
    // Store the rate certificate in contract storage
    // Note that there may be multiple valid rate certificates for the block.
    // Note: Presumably no validation is needed here because all conditions are checked when the RC is used.
    store_rate_certificate(rate_certificate)
}

// Update an existing rate certificate.
function update_rate_certificate(
    old_rate_certificate: RateCertificate, 
    new_rate_certificate: RateCertificate,
    proof_of_failure: ???, // TODO:
) -> void {
    // TODO: Either RCs will be unique by the combo of block root and provider address or we'll need to
    // TODO: add a unique id to the RC struct.
    // ...

    // Verify that the rate certificate relacment is valid:
    // TODO:
    // 1) Reproduce the logic for provide selection for the period?
    // 2) Verify the provided proof that the old old provider failed?
}

// Store a new periodic commitment. 
// Note: that this method is invoked with a value amount that is either payable directly to the contract or
// designated to be sequestered from the provider's stake, depending on how bonds are implemented.
function post_periodic_commitment(commitment: PeriodicCommitment, payable_amount: TokenValue) -> void {
    // Store the commitments in contract storage associated with the current block number.
    store_commitments(msg.sender, block.number, commitment)

    // Store the bond amount or allocate it from the provider's stake.
    store_bond_amount(msg.sender, payable_amount)
}

// Settle multiple time periods (allowing for aggregation optimizations)
function settle_multiple(requests: Array<SettlementRequest>): void {
    for request in requests { settle_request(request) }
}

// Settle a single time period
function settle(request: SettlementRequest): void {

    // Get the on-chain commitments for the provider and time period [assuming contract storage here].
    // Note that since p and q committments are always stored with the current block number when posted, 
    // they serve as witness that the commitments were made during the requested settlement period.
    provider = msg.sender // Address of the provider (caller)
    commitment_p, commitment_q = get_stored_commitments(provider, request.period)

    //
    // Verify the p, r, and q KZG openings.
    // i.e. Confirm that the openings are individually consistent with their respective commitments.
    // 
    s = trusted_setup()
    commitment_r = request.block_root_id
    assert verify_kzg_proof(commitment_r, request.r_opening.proof, request.r_opening.z_eval, request.r_opening.y_eval, s)
    assert verify_kzg_proof(commitment_p, request.p_opening.proof, request.p_opening.z_eval, request.p_opening.y_eval, s)
    assert verify_kzg_proof(commitment_q, request.q_opening.proof, request.q_opening.z_eval, request.q_opening.y_eval, s)

    //
    // Verify the correspondence between p, r, and the beacon value for the period.
    // i.e. the p (periodic) value matches the r (original data) value *at* the 
    // beacon-selected subblock index in r.
    // 
    
    // Determine the random beacon subblock index for the period [assuming accessible on-chain]
    // Note that this assumes that the beacon selection is the same for all indexes (z_eval) in the p poly.
    // If that is undesirable for some reason we can incorporate the p_opening.z_eval into the beacon.
    beacon_selected_subblock_index = beacon_for_period(request.period)

    // Assert that the r opening is for the beacon-selected subblock
    // i.e. The r opening is proving the correct subblock
    assert request.r_opening.z_eval == beacon_selected_subblock_index

    //
    // Assert that the p commitment value and r block commitment value match.
    // i.e. the data comitted for the period matches the original subblock data.
    //
    assert request.p_opening.y_eval == request.r_opening.y_eval

    //
    // Verify the correspondence between q and r:
    // Assert that the q opening value matches the client block root id.
    // i.e. the provider committed to the client block in question during the period.
    //
    block_root_id = request.r_opening.commitment
    assert request.q_opening.y_eval == block_root_id

    // About q_poly: Note that the q_poly z_eval is used only in verifying the kzg opening and has no
    // cohort-recognizable semantics here.  In order for the cohort to do its job of scanning the periodic
    // q poly commitments (utilizing the blob space data) it must search for known block root ids (r commits) in q.

    // Get all valid rate certificates for the block [assuming contract storage here]
    rate_certificates = get_rate_certificates(block_root_id)

    // Repeat the remaining logic for each valid rate certificate
    // for rc in rate_certificates { ...

    // Confirm that the rate certificate designates this provider for the settlement.
    assert rate_certificate.provider == provider

    // TODO: Handle the bond for the commitments:
    // TODO: 1) Verify that the bond for the commit was of the correct size to cover the included commitments.
    // TODO: Alternately how do we prove to the contract that the RC bond amounts sum to the total bond?
    
    // Release or refund the bond for the commitments.
    // If bonding is integrated with the stake then this method will just un-escrowing the amount.
    // If bonding is not integrated with the stake then the amount can be included in the payment below.
    release_bond(provider, request.period)

    // Issue payment
    client = rate_certificate.client
    payment = rate_certificate.commitment_payment
    send_payment(client, provider, payment)

    // Mark the period as settled, preventing repeat claims.
    // Note that the logic must apply to any potential provider making a rival claim,
    // so simply removing the settled provider's commitments is not sufficient.
    // e.g. Maybe we structure the storage to allow for removing all commitments for the period?
    mark_payment(provider, request.period)

    // Clean up and reclaim or re-use any storage no longer needed for this period.
    clean_up_storage()
}



