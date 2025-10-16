use starknet::ContractAddress;
use crate::structs::structs::*;
use crate::enums::enums::*;


#[starknet::interface]
pub trait IProposalForm<TContractState> {
    fn submit_proposal(
        ref self: TContractState,
        proposer: ContractAddress,
        policy_class_code: u8,
        subject_matter: ByteArray,
        sum_insured: u256,
        premium_frequency_code: u8,
        frequency_factor: u8,
    );
    fn update_proposal(
        ref self: TContractState,
        proposal_id: u256, 
        subject_matter: ByteArray,
        sum_insured: u256,
        premium_frequency_code: u8,
        frequency_factor: u8,
        has_reinsurance: bool,
        reinsurance_txn_id: u256
    );
    fn get_proposal_by_id(
        self: @TContractState,
        proposal_id: u256
    ) -> ProposalFormResponse;
    fn get_min_premium_rate(
        self: @TContractState
    ) -> u16;
    fn set_min_premium_rate(
        ref self: TContractState,
        new_rate: u16
    );
    fn get_max_premium_rate(
        self: @TContractState
    ) -> u16;
    fn set_max_premium_rate(
        ref self: TContractState,
        new_rate: u16
    );
    fn get_min_coverage_amount(
        self: @TContractState
    ) -> u256;
    fn set_min_coverage_amount(
        ref self: TContractState,
        new_amount: u256
    );
    fn get_max_coverage_amount(
        self: @TContractState
    ) -> u256;
    fn set_max_coverage_amount(
        ref self: TContractState,
        new_amount: u256
    );
    fn assess_proposal_by_risk_service(
        ref self: TContractState,
        proposal_id: u256,
        has_kyc: bool,
        risk_analytics_approved: bool,
        premium_payable: u256,
        premium_rate: u16,
        risk_score: u256,
        proposal_status_code: u8,
        rejection_reason_code: u8,
        has_reinsurance: bool,
        reinsurance_txn_id: u256,
    );

    fn assess_proposal_by_governance(
        ref self: TContractState,
        proposal_id: u256,
        has_kyc: bool,
        governance_approved: bool,
        premium_payable: u256,
        premium_rate: u16,
        risk_score: u256,
        proposal_status_code: u8,
        rejection_reason_code: u8,
        has_reinsurance: bool,
        reinsurance_txn_id: u256,
    );
    
    fn set_treasury_address(
        ref self: TContractState,
        treasury_address: ContractAddress
    );

    fn set_policy_minting_address(
        ref self: TContractState,
        policy_minting_address: ContractAddress
    );

    fn set_claims_contract_address(
        ref self: TContractState,
        claims_contract_address: ContractAddress
    );
}



#[starknet::interface]
pub trait IPolicyNFT<TContractState> {
    fn mint_policy(
        ref self: TContractState,
        proposal_id: u256
    ) -> u256;
    fn burn_policy(ref self: TContractState, token_id: u256, reason_index: u8);
    fn get_policy_data(self: @TContractState, token_id: u256) -> PolicyDataResponse;
    fn set_base_uri(ref self: TContractState, new_base_uri: ByteArray);
    fn update_policy_data(
        ref self: TContractState,
        token_id: u256, 
        subject_matter: ByteArray,
        sum_insured: u256,
        premium: u256,
        premium_frequency_code: u8,
        frequency_factor: u8,
        update_type_code: u8,
        endorsement_amount: u256,
        has_reinsurance: bool,
        reinsurance_txn_id: u256
    );
    fn add_claim_to_policy(
        ref self: TContractState,
        policy_id: u256,
        claim_id: u256,
        claim_amount: u256
    );

    fn set_treasury_address(
        ref self: TContractState,
        treasury_address: ContractAddress
    );

    fn set_proposal_form_address(
        ref self: TContractState,
        proposal_form_address: ContractAddress
    );

    fn set_claims_contract_address(
        ref self: TContractState,
        claims_contract_address: ContractAddress
    );    
    
    fn get_base_uri(
        self: @TContractState
    ) -> ByteArray;
}




#[starknet::interface]
pub trait IClaim<TContractState> {
    fn file_claim(
        ref self: TContractState,
        policy_id: u256,
        claimant: ContractAddress,
        claim_description: ByteArray,
        claim_amount: u256,
        alternative_account: ContractAddress,
        policy_class_code: u8,
        proof_urls: Array<ByteArray>
    ) -> u256;

    fn update_claim(
        ref self: TContractState,
        claim_id: u256,
        policy_id: u256,
        claimant: ContractAddress,
        claim_description: ByteArray,
        claim_amount: u256,
        alternative_account: ContractAddress,
        policy_class_code: u8,
        proof_urls: Array<ByteArray>
    );

    fn get_claim_by_id(
        self: @TContractState,
        claim_id: u256
    ) -> InsuranceClaimResponse;

    fn get_claim_evidence_urls_for_current_claim(
        self: @TContractState,
        claim_id: u256
    ) -> Array<ByteArray>;

    fn assess_claim_by_risk_analytics(
        ref self: TContractState,
        claim_id: u256,
        risk_analytics_approved: bool,
        is_approved: bool,
        is_repudiated: bool,
        repudiation_reason_code: u8,
        claim_status_code: u8,
        claim_type_code: u8,
        approved_settlement_amount: u256,        
    );

    fn assess_claim_by_governance(
        ref self: TContractState,
        claim_id: u256,
        governance_approved: bool,
        is_approved: bool,
        is_repudiated: bool,
        repudiation_reason_code: u8,
        claim_status_code: u8,
        claim_type_code: u8,
        approved_settlement_amount: u256,
    );

    fn set_claim_as_settled(
        ref self: TContractState,
        claim_id: u256
    );

    fn set_claim_as_repudiated(
        ref self: TContractState,
        claim_id: u256
    );

    fn get_settled_claims(
        self: @TContractState
    ) -> Array<InsuranceClaimResponse>;

    fn get_repudiated_claims(
        self: @TContractState
    ) -> Array<InsuranceClaimResponse>;

    fn get_pending_claims(
        self: @TContractState
    ) -> Array<InsuranceClaimResponse>;

    fn get_escalated_claims(
        self: @TContractState
    ) -> Array<InsuranceClaimResponse>;

    fn get_all_claims(
        self: @TContractState
    ) -> Array<InsuranceClaimResponse>;

    fn escalate_claim(
        ref self: TContractState,
        claim_id: u256,
        is_escalated: bool,
        escalation_reason: ByteArray,
        proof_urls: Array<ByteArray>
    );

    fn settle_claim(
        ref self: TContractState,
        claim_id: u256,
    );

    fn set_treasury_address(
        ref self: TContractState,
        treasury_address: ContractAddress
    );

    fn get_treasury_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_proposal_form_address(
        ref self: TContractState,
        proposal_form_address: ContractAddress
    );

    fn get_proposal_form_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_policy_minting_address(
        ref self: TContractState,
        policy_minting_address: ContractAddress
    );

    fn get_policy_minting_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_governance_address(
        ref self: TContractState,
        governance_address: ContractAddress
    );

    fn get_governance_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_auto_approval_limit(
        ref self: TContractState,
        auto_approval_limit: u256
    );

    fn get_auto_approval_limit(
        self: @TContractState,
    ) -> u256;

    fn set_max_claim_amount_payable(
        ref self: TContractState,
        max_claim_amount_payable: u256
    );

    fn get_max_claim_amount_payable(
        self: @TContractState,
    ) -> u256;    
}



#[starknet::interface] 
pub trait ITreasuryManagement<TContractState> {
    fn pay_premium(
        ref self: TContractState,
        proposal_id: u256,
        payer_address: ContractAddress,
    ) -> u256;

    fn update_premium_payment(
        ref self: TContractState,
        transaction_id: u256,
        policy_id: u256,
        txn_hash: felt252,
        payment_status_code: u8 
    );

    fn get_premium_payment(
        self: @TContractState,
        transaction_id: u256
    ) -> PremiumPaymentResponse;

    fn pay_claim(
        ref self: TContractState,
        policy_id: u256,
        claim_id: u256,
        policyholder: ContractAddress,
        third_party_account: ContractAddress,
        settlement_source_code: u8
    ) -> u256;

    fn update_claim_payment(
        ref self: TContractState,
        transaction_id: u256,
        third_party_account: ContractAddress,
        txn_hash: felt252,
        settlement_status_code: u8,
        settlement_source_code: u8
    );

    fn get_claim_payment(
        self: @TContractState,
        transaction_id: u256
    ) -> ClaimPaymentResponse;

    fn purchase_stindem(
        ref self: TContractState,
        buyer_address: ContractAddress,
        quantity: u256,
    ) -> u256;

    fn update_stindem_purchase_detail(
        ref self: TContractState,
        transaction_id: u256,
        txn_hash: felt252,
        payment_status_code: u8
    );

    fn get_stindem_purchase_detail(
        self: @TContractState,
        transaction_id: u256
    ) -> NativeTokenPurchaseResponse;

    fn recover_stindem_from_market(
        ref self: TContractState,
        seller_address: ContractAddress,
        quantity: u256,
    ) -> u256;

    fn update_stindem_recovery_from_market(
        ref self: TContractState,
        transaction_id: u256,
        txn_hash: felt252,
        payment_status_code: u8
    );

    fn get_stindem_recovery_txn_detail(
        self: @TContractState,
        transaction_id: u256
    ) -> NativeTokenRecoveryResponse;

    fn purchase_voting_commitment(
        ref self: TContractState,
        seller_address: ContractAddress,
    ) -> (u256, felt252);

    fn update_voting_commitment_purchase(
        ref self: TContractState,
        transaction_id: u256,
        txn_hash: felt252,
        payment_status_code: u8
    );

    fn get_voting_commitment_purchase_detail(
        self: @TContractState,
        transaction_id: u256
    ) -> PurchaseVotingCommitmentResponse;

    fn initiate_reinsurance_premium_payment(
        ref self: TContractState,
        insured_proposal_id: u256,
        insured_policy_id: u256,
        reinsurer_id: u256,
        reinsurance_payment_address: ContractAddress,
        percentage_reinsurance: u16,
        gross_sum_insured: u256,
        ceded_sum_insured: u256,
        gross_premium: u256,
        ceded_premium: u256,
    ) -> u256;

    fn update_reinsurance_premium_payment_detail(
        ref self: TContractState,
        transaction_id: u256,
        txn_hash: felt252,
        reinsurance_doc_url: ByteArray,
        payment_status_code: u8,
        reinsurance_status_code: u8
    );

    fn get_reinsurance_premium_payment_detail(
        self: @TContractState,
        transaction_id: u256
    ) -> CreditReinsuranceResponse;

    fn initiate_claim_recovery_from_reinsurance(
        ref self: TContractState,
        reinsurance_payment_id: u256,
        insured_proposal_id: u256,
        insured_policy_id: u256,
        claim_id: u256,
        insured: ContractAddress,
        reinsurer_id: u256,
        reinsurance_payment_address: ContractAddress,
        gross_claim_amount: u256,
    ) -> u256;

    // fn update_claim_recovery_from_reinsurance(
    //     ref self: TContractState,
    //     transaction_id: u256,
    //     claim_id: u256,
    //     reinsurance_payment_id: u256,
    //     reinsurance_payment_address: ContractAddress,
    //     txn_hash: ByteArray,
    //     claim_discharge_voucher_url: ByteArray,
    //     settlement_status_code: u8,
    //     reinsurance_status_code: u8 
    // );

    // fn get_claim_recovery_from_reinsurance_detail(
    //     self: @TContractState,
    //     transaction_id: u256
    // ) -> DebitReinsuranceResponse;

    // fn create_new_reinsurer(
    //     ref self: TContractState,
    //     reinsurer_name: ByteArray,
    //     reinsurer_head_office: ByteArray,
    //     reinsurer_fiat_account: ByteArray,
    //     reinsurer_web_site: ByteArray,
    //     risk_capacity: u256,
    //     contract_type_code: u8,
    // ) -> u256;

    // fn update_reinsruer_detail(
    //     ref self: TContractState,
    //     reinsurer_id: u256,
    //     reinsurer_name: ByteArray,
    //     reinsurer_head_office: ByteArray,
    //     reinsurer_fiat_account: ByteArray,
    //     reinsurer_web_site: ByteArray,
    //     risk_capacity: u256,
    //     contract_type_code: u8,
    //     total_obligation_offered: u256,
    //     total_obligation_fulfilled: u256,
    //     reliability_factor: u8,
    // );

    // fn get_reinsurer_by_id(
    //     self: @TContractState,
    //     reinsurer_id: u256
    // ) -> ReinsurerResponse;

    fn set_proposal_form_address(
        ref self: TContractState,
        proposal_form_address: ContractAddress
    );

    fn get_proposal_form_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_policy_minting_address(
        ref self: TContractState,
        policy_minting_address: ContractAddress
    );

    fn get_policy_minting_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_governance_address(
        ref self: TContractState,
        governance_address: ContractAddress
    );

    fn get_governance_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_claims_contract_address(
        ref self: TContractState,
        claims_contract_address: ContractAddress
    );

    fn get_claims_contract_address(
        self: @TContractState,
    ) -> ContractAddress;

        
    // STINDEM token address
fn set_stindem_token_address(
    ref self: TContractState,
    stindem_token_address: ContractAddress
);

fn get_stindem_token_address(
    self: @TContractState,
) -> ContractAddress;

// Conversion rates
fn set_current_stindem_to_strk_value(
    ref self: TContractState,
    value: u256
);

fn get_current_stindem_to_strk_value(
    self: @TContractState,
) -> u256;

fn set_current_stindem_to_eth_value(
    ref self: TContractState,
    value: u256
);

fn get_current_stindem_to_eth_value(
    self: @TContractState,
) -> u256;

fn set_current_stindem_to_btc_value(
    ref self: TContractState,
    value: u256
);

fn get_current_stindem_to_btc_value(
    self: @TContractState,
) -> u256;

fn set_current_stindem_to_usd_value(
    ref self: TContractState,
    value: u256
);

fn get_current_stindem_to_usd_value(
    self: @TContractState,
) -> u256;

fn set_current_strk_to_usd_value(
    ref self: TContractState,
    value: u256
);

fn get_current_strk_to_usd_value(
    self: @TContractState,
) -> u256;

fn set_current_strk_to_eth_value(
    ref self: TContractState,
    value: u256
);

fn get_current_strk_to_eth_value(
    self: @TContractState,
) -> u256;

fn set_current_strk_to_btc_value(
    ref self: TContractState,
    value: u256
);

fn get_current_strk_to_btc_value(
    self: @TContractState,
) -> u256;

// Currency balances
fn set_starknet_indemnify_usd_balance(
    ref self: TContractState,
    balance: u256
);

fn get_starknet_indemnify_usd_balance(
    self: @TContractState,
) -> u256;

fn set_starknet_indemnify_strk_balance(
    ref self: TContractState,
    balance: u256
);

fn get_starknet_indemnify_strk_balance(
    self: @TContractState,
) -> u256;

fn set_starknet_indemnify_stindem_balance(
    ref self: TContractState,
    balance: u256
);

fn get_starknet_indemnify_stindem_balance(
    self: @TContractState,
) -> u256;

fn set_starknet_indemnify_eth_balance(
    ref self: TContractState,
    balance: u256
);

fn get_starknet_indemnify_eth_balance(
    self: @TContractState,
) -> u256;

fn set_starknet_indemnify_btc_balance(
    ref self: TContractState,
    balance: u256
);

fn get_starknet_indemnify_btc_balance(
    self: @TContractState,
) -> u256;

// Voting quantity
fn set_stindem_qty_to_vote(
    ref self: TContractState,
    quantity: u256
);

fn get_stindem_qty_to_vote(
    self: @TContractState,
) -> u256;

// STRK contract address
fn set_strk_contract_address(
    ref self: TContractState,
    strk_contract_address: ContractAddress
);

fn get_strk_contract_address(
    self: @TContractState,
) -> ContractAddress;

// Treasury accounts
fn set_starknet_indemnify_treasury_account(
    ref self: TContractState,
    treasury_account: ContractAddress
);

fn get_starknet_indemnify_treasury_account(
    self: @TContractState,
) -> ContractAddress;

fn set_starknet_indemnify_stindem_treasury(
    ref self: TContractState,
    stindem_treasury: ContractAddress
);

fn get_starknet_indemnify_stindem_treasury(
    self: @TContractState,
) -> ContractAddress;

}


