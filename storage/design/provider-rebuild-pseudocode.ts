// 
// Data Types
//
// @See DataTypes in settlement-contract-pseudocode.txt 
//
BlockId: Point     // The commitment to the client block r poly, a.k.a. the block root id.

// Contextual information about a provider cohort storing data for one client.
// Note: All of this information can be gathered by viewing the on-chain rate certificates for a given client.
struct ClientCohort {
    // The client who owns this set of data
    client: Address

    // A list of block ids comprising the set of client data
    block_ids: Array<BlockId> 

    // Note: Provider contact information
    // If selection is made via the Orchid directory then the Orchid location contract will have contact info.
    // Additionally if the block provider is designated in the Rate Certificate the RC could store current contact info.
    // ...
}

//
// Provider cohort data availability monitoring and rebuild operations
//

// Called by a provider for each new time period.
function on_new_time_period(current_period: TimePeriod) -> void {
    // Dispatch the "check cohort" operation for each cohort in which the provider participates.
    cohorts = get_my_cohorts()
    for cohort in cohorts { check_cohort(cohort, current_period) }
}

// Evaluate the specified provider cohort for the current time period
function check_cohort(cohort: ClientCohort, current_period: TimePeriod) {

    // Verify that committments were made for each block assigned to this cohort
    for block_id in cohort.block_ids {

        // Get the current rate certificates for this block. [Assumed available on-chain].
        block_rate_certificates: List<RateCertificate> = get_rate_certificates(block_id)

        // We are not tasked with monitoring a client block for which no rate certificate has been posted.
        assert block_rate_certificates.isNotEmpty()

        // For each block RC check that the designated provider has committed during the time period.
        for rate_certificate in block_rate_certificates {
            provider = rate_certificate.provider
            provider_committed_ok = provider_committed_within_grace_period(provider, block_id, current_period)

            if (!provider_committed_ok) {
                // The provider failed to commit to the block as required.
                rebuild(rate_certificate)
            }
        }
    }
}

function provider_has_committed_within_grace_period(provider: Address, block_id: BlockId, current_period: TimePeriod) -> bool {
    // Any grace period can only extend as far as blob space availability
    assert COMMITMENT_GRACE_PERIOD <= MAX_BLOB_SPACE_PERIODS

    // Search backwards some number of past periods for a commitment by the provider
    for period in range(current_period, current_period - COMMITMENT_GRACE_PERIOD) {
        if provider_has_committed(provider, block_id, period) {
            return true
        }
    }
    return false
}

// Verify that a provider has committed to a given block during the specified time period
function provider_has_committed(provider: Address, block_id: BlockId, period: TimePeriod) -> bool {
    // Assert that the period to check is recent enough that the blob space data is still available
    assert period >= get_current_period() - MAX_BLOB_SPACE_PERIODS

    // Get the on-chain periodic commitments for this provider and time period
    _, commitment_q = get_stored_commitments(provider, period)

    // Get the q poly from blob space 
    q_poly = get_q_poly_from_blob_space(provider, period)

    // Confirm that the q commitment matches the q blob
    assert commitment_q == kzg_commit(q_poly, trusted_setup())

    // Verify that the q poly contains the block id (one of its values is the block id)
    // This is done by evaluating the poly at some or all of its indexes (e.g. the first 4096)
    assert q_poly_contains_block_id(q_poly, block_id)

    return true
}


// Begin a rebuild by prompting a new provider to claim the rate certificate for the block.
// This method is called periodically until the rate certificate is claimed.
function rebuild(failed_rate_certificate: RateCertificate) -> Status {

    // Using some on-chain or off-chain deterministic process nominate a new prospective provider for this time period.
    next_provider = choose_next_provider(...)

    // Don't immediately choose the same provider again.
    assert next_provider != failed_rate_certificate.provider

    // Get the latest rate certificates / providers for the block (on-chain)
    latest_rate_certificates = get_rate_certificates(block_id) 
    latest_providers = latest_rate_certificates.map {$0.provider}

    // Check if the failed rate certificate is still present in the latest set.
    // (i.e. is the rebuild still needed?)
    if latest_rate_certificates.doesNotContain(failed_rate_certificate) {
        // The failed provider rate certificate has already been been updated or removed.

        // TODO: What validation of the new provider should we do here?
        // If the RC update method validates the new provider then we are good:
        // Proceed with "greeting" the new provider and end the rebuild logic.
        // If we are doing a stake and challenge scheme then we should kick off an async check of the new provider.
        // ...
    }

    // Continue with the rebuild process...

    // Attempt to contact the next provider
    prod_new_provider_to_claim_rc(provider, failed_rate_certficate)

    // Schedule a call to run this function again after a period of time.
    schedule_next_rebuild_recheck( /* ... */ )
}



function prod_new_provider_to_claim_rc(provider: Address, failed_rate_certficiate: RateCertificate) {
    // Use some communication mechanism to contact the prospective provider and ask them to replace the
    // failed provider by claiming the rate certificate.
    // ...
}


//
// Provider cohort rebuild operations
//

// 
// Receive a request from the cohort to participate in a rebuild.
// Evaluate the request and if it looks good then proceed to claim the rate certificate and rebuild the shard.
//
function evaluate_request_to_rebuild(failed_rate_certificate: RateCertificate) {
    // Reproduce the logic used by the calling cohort member(s) to verify that the rate certificate
    // still exists and represents a failed provider commitment.
    // ...
    assert ...
    
    // Reproduce the logic used by the cohort to verify that we are the valid replacement provider for this time period.
    // ...
    assert ...
    
    // Decide if the rate offered in the rate certificate is acceptable.
    // ...
    assert ...

    // Try to determine if we have *time* to accomplish the data download / rebuild before the beacon invaliates 
    // our selection. i.e. Can we download the data and claim the rate certificate before the next period?
    // ...
    assert estimated_time_to_rebuild(failed_rate_certificate) < time_until_next_period()
    
    // Everything looks good.  Proceed to download the data and claim the rate certificate.
    
    // Wait to be solicited with requests for selling us the shard data by current cohort nodes of the correct node type.
    // (Note that incentives are better when the cohort reaches out to the new provider rather than the other way around.)
    // ...
    receive_data_offers()
    if (need_more_data(failed_rate_certificate)) {
        reschedule_rebuild_request(failed_rate_certificate) // try again after more data is available
        return;
    }

    // Note: If the structure of the r poly is not protocol-determined it will need to be agreed-upon here.
    
    // Update the rate certificate:
    // Construct the rate certificate, setting the provider to our address, and call the settlement contract method.
    new_rate_certificate = construct_rate_certificate(failed_rate_certificate, new_provider)

    // Gather off-chain information required to prove to the contract that the provider has actually failed.
    // e.g. some proof that the q poly commitment does not contain the block id.
    proof_of_failure = // ...

    // Call the settlement contract method to replace the rate certificate.
    replace_rate_certificate(failed_rate_certificate, new_rate_certificate, proof_of_failure)
    
    // Begin posting periodic commitments for the shard.
    // Probably a bond associated with each commitment (bonded commitment scheme)
    // ...
    begin_posting_periodic_commitments(new_rate_certificate)
}


