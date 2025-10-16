use starknet::ContractAddress;
use crate::enums::enums::*;

    #[derive(Drop, starknet::Store, Serde, Clone)]
    pub struct ProposalForm {
        pub proposal_id: u256,
        pub proposer: ContractAddress,
        pub policy_class_code: u8,
        pub subject_matter: ByteArray,
        pub sum_insured: u256,
        pub premium_payable: u256,
        pub premium_frequency_code: u8,
        pub frequency_factor: u8,
        pub has_kyc: bool,
        pub submission_date: u64,
        pub last_updated: u64,
        pub expiration_date: u64,
        pub is_active: bool,
        pub is_expired: bool,
        pub is_premium_paid: bool,
        pub risk_analytics_approved: bool,
        pub governance_approved: bool,
        pub proposal_status_code: u8,
        pub rejection_reason_code: u8,
        pub risk_score: u256,
        pub premium_rate: u16,
        pub has_reinsurance: bool,
        pub reinsurance_txn_id: u256,
    }





    #[derive(Drop, Serde, Clone)]
    pub struct ProposalFormResponse {
        pub proposal_id: u256,
        pub proposer: ContractAddress,
        pub policy_class: PolicyClass,
        pub subject_matter: ByteArray,
        pub sum_insured: u256,
        pub premium_payable: u256,
        pub premium_frequency: PremiumFrequency,
        pub frequency_factor: u8,
        pub has_kyc: bool,
        pub submission_date: u64,
        pub last_updated: u64,
        pub expiration_date: u64,
        pub is_active: bool,
        pub is_expired: bool,
        pub is_premium_paid: bool,
        pub risk_analytics_approved: bool,
        pub governance_approved: bool,
        pub proposal_status: ProposalStatus,
        pub rejection_reason: RejectionReason,
        pub risk_score: u256,
        pub premium_rate: u16,
        pub has_reinsurance: bool,
        pub reinsurance_txn_id: u256,
    }




    #[derive(Drop, starknet::Store, Serde, Clone)]
    pub struct PolicyData {
        pub policy_id: u256,
        pub proposal_id: u256,
        pub policyholder: ContractAddress,
        pub policy_class_code: u8,
        pub subject_matter: ByteArray,
        pub sum_insured: u256,
        pub premium: u256,
        pub premium_frequency_code: u8,
        pub frequency_factor: u8,
        pub start_date: u64,
        pub expiration_date: u64,
        pub is_active: bool,
        pub is_expired: bool,
        pub claims_count: u256,
        pub has_claimed: bool,
        pub has_reinsurance: bool,
        pub reinsurance_txn_id: u256,
        pub aggregate_claim_amount: u256
    }


    #[derive(Drop, Serde, Clone)]
    pub struct PolicyDataResponse {
        pub policy_id: u256,
        pub proposal_id: u256,
        pub policyholder: ContractAddress,
        pub policy_class: PolicyClass,
        pub subject_matter: ByteArray,
        pub sum_insured: u256,
        pub premium: u256,
        pub premium_frequency: PremiumFrequency,
        pub frequency_factor: u8,
        pub start_date: u64,
        pub expiration_date: u64,
        pub is_active: bool,
        pub is_expired: bool,
        pub claims_count: u256,
        pub has_claimed: bool,
        pub has_reinsurance: bool,
        pub reinsurance_txn_id: u256,
        pub claim_ids: Array<u256>,
        pub aggregate_claim_amount: u256
    }



        #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct InsuranceClaim {
        pub claim_id: u256,
        pub policy_id: u256,
        pub proposal_id: u256,
        pub claimant: ContractAddress,
        pub claim_description: ByteArray,
        pub claim_amount: u256,
        pub approved_settlement_amount: u256,
        pub alternative_account: ContractAddress,
        pub policy_class_code: u8,
        pub claim_status_code: u8,
        pub claim_type_code: u8,
        pub submission_date: u64,
        pub updated_at: u64,
        pub is_approved: bool,
        pub approved_at: u64,
        pub is_repudiated: bool,
        pub repudiated_at: u64,
        pub risk_analytics_approved: bool,
        pub governance_approved: bool,
        pub is_escalated: bool,
        pub escalation_reason: ByteArray,
        pub repudiation_reason_code: u8
    }


    #[derive(Drop, Serde, Clone)]
    pub struct InsuranceClaimResponse {
        pub claim_id: u256,
        pub policy_id: u256,
        pub proposal_id: u256,
        pub claimant: ContractAddress,
        pub claim_description: ByteArray,
        pub claim_amount: u256,
        pub approved_settlement_amount: u256,
        pub alternative_account: ContractAddress,
        pub policy_class: PolicyClass,
        pub claim_status: ClaimStatus,
        pub claim_type: ClaimType,
        pub submission_date: u64,
        pub updated_at: u64,
        pub is_approved: bool,
        pub approved_at: u64,
        pub is_repudiated: bool,
        pub repudiated_at: u64,
        pub risk_analytics_approved: bool,
        pub governance_approved: bool,
        pub is_escalated: bool,
        pub escalation_reason: ByteArray,
        pub claim_evidence_urls: Array<ByteArray>,
        pub repudiation_reason: ClaimRepudiationReason
    }


    #[derive(Drop, Serde, Clone)]
    pub struct ClaimEvidence {
        pub policy_id: u256,
        pub submission_date: u64,
        pub proof_urls: Array<ByteArray>,
    }


    #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct PremiumPayment {
        pub transaction_id: u256,
        pub proposal_id: u256,
        pub policy_id: u256,
        pub payer_address: ContractAddress,
        pub policyholder: ContractAddress,
        pub amount_paid: u256,
        pub sum_insured: u256,
        pub payment_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub payment_status_code: u8 
    }


    #[derive(Drop, Serde, Clone)]
    pub struct PremiumPaymentResponse {
        pub transaction_id: u256,
        pub proposal_id: u256,
        pub policy_id: u256,
        pub payer_address: ContractAddress,
        pub policyholder: ContractAddress,
        pub amount_paid: u256,
        pub sum_insured: u256,
        pub payment_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub payment_status: PaymentStatus
    }

    #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct NativeTokenPurchase {
        pub transaction_id: u256,
        pub buyer_address: ContractAddress,
        pub seller_address: ContractAddress,
        pub token_address: ContractAddress,
        pub token_symbol: ByteArray,
        pub quantity: u256,
        pub unit_price: u256,
        pub total_price_paid: u256,
        pub payment_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub payment_status_code: u8
    }

    #[derive(Drop, Serde, Clone)]
    pub struct NativeTokenPurchaseResponse {
        pub transaction_id: u256,
        pub buyer_address: ContractAddress,
        pub seller_address: ContractAddress,
        pub token_address: ContractAddress,
        pub token_symbol: ByteArray,
        pub quantity: u256,
        pub unit_price: u256,
        pub total_price_paid: u256,
        pub payment_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub payment_status: PaymentStatus
    }


    #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct ClaimPayment {
        pub transaction_id: u256,
        pub proposal_id: u256,
        pub policy_id: u256,
        pub claim_id: u256,
        pub policyholder: ContractAddress,
        pub third_party_account: ContractAddress,
        pub claim_amount: u256,
        pub approved_settlement_amount: u256,
        pub settlement_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub settlement_status_code: u8,
        pub settlement_source_code: u8
    }


    #[derive(Drop, Serde, Clone)]
    pub struct ClaimPaymentResponse {
        pub transaction_id: u256,
        pub proposal_id: u256,
        pub policy_id: u256,
        pub claim_id: u256,
        pub policyholder: ContractAddress,
        pub third_party_account: ContractAddress,
        pub claim_amount: u256,
        pub approved_settlement_amount: u256,
        pub settlement_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub settlement_status: PaymentStatus,
        pub settlement_source: ClaimsPaymentSource
    }


    #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct NativeTokenRecovery {
        pub transaction_id: u256,
        pub seller_address: ContractAddress,
        pub buyer_address: ContractAddress,
        pub token_address: ContractAddress,
        pub token_symbol: ByteArray,
        pub quantity: u256,
        pub unit_price: u256,
        pub total_price_paid: u256,
        pub payment_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub payment_status_code: u8
    }
    

    #[derive(Drop, Serde, Clone)]
    pub struct NativeTokenRecoveryResponse {
        pub transaction_id: u256,
        pub seller_address: ContractAddress,
        pub buyer_address: ContractAddress,
        pub token_address: ContractAddress,
        pub token_symbol: ByteArray,
        pub quantity: u256,
        pub unit_price: u256,
        pub total_price_paid: u256,
        pub payment_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub payment_status: PaymentStatus
    }


    #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct PurchaseVotingCommitment {
        pub transaction_id: u256,
        pub seller_address: ContractAddress,
        pub buyer_address: ContractAddress,
        pub token_address: ContractAddress,
        pub token_symbol: ByteArray,
        pub quantity: u256,
        pub unit_price: u256,
        pub total_price_paid: u256,
        pub payment_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub payment_status_code: u8
    }


    #[derive(Drop, Serde, Clone)]
    pub struct PurchaseVotingCommitmentResponse {
        pub transaction_id: u256,
        pub seller_address: ContractAddress,
        pub buyer_address: ContractAddress,
        pub token_address: ContractAddress,
        pub token_symbol: ByteArray,
        pub quantity: u256,
        pub unit_price: u256,
        pub total_price_paid: u256,
        pub payment_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub payment_status: PaymentStatus
    }


    #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct CreditReinsurance {
        pub transaction_id: u256,
        pub insured_proposal_id: u256,
        pub insured_policy_id: u256,
        pub insured: ContractAddress,
        pub reinsurer_id: u256,
        pub reinsurance_payment_address: ContractAddress,
        pub reinsurer_name: ByteArray,
        pub percentage_reinsurance: u16,
        pub gross_sum_insured: u256,
        pub ceded_sum_insured: u256,
        pub gross_premium: u256,
        pub ceded_premium: u256,
        pub payment_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub reinsurance_doc_url: ByteArray,
        pub payment_status_code: u8,
        pub reinsurance_status_code: u8
    }


    #[derive(Drop, Serde, Clone)]
    pub struct CreditReinsuranceResponse {
        pub transaction_id: u256,
        pub insured_proposal_id: u256,
        pub insured_policy_id: u256,
        pub insured: ContractAddress,
        pub reinsurer_id: u256,
        pub reinsurance_payment_address: ContractAddress,
        pub reinsurer_name: ByteArray,
        pub percentage_reinsurance: u16,
        pub gross_sum_insured: u256,
        pub ceded_sum_insured: u256,
        pub gross_premium: u256,
        pub ceded_premium: u256,
        pub payment_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub reinsurance_doc_url: ByteArray,
        pub payment_status: PaymentStatus,
        pub reinsurance_status: ReinsuranceStatus
    }



    #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct DebitReinsurance {
        pub transaction_id: u256,
        pub reinsurance_payment_id: u256,
        pub insured_proposal_id: u256,
        pub insured_policy_id: u256,
        pub claim_id: u256,
        pub insured: ContractAddress,
        pub reinsurer_id: u256,
        pub reinsurance_payment_address: ContractAddress,
        pub reinsurer_name: ByteArray,
        pub percentage_reinsurance: u16,
        pub gross_sum_insured: u256,
        pub ceded_sum_insured: u256,
        pub gross_premium: u256,
        pub ceded_premium: u256,
        pub gross_claim_amount: u256,
        pub reinsurance_claim_apportionment: u256,
        pub settlement_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub reinsurance_doc_url: ByteArray,
        pub claim_discharge_voucher_url: ByteArray,
        pub settlement_status_code: u8,
        pub reinsurance_status_code: u8
    }


    #[derive(Drop, Serde, Clone)]
    pub struct DebitReinsuranceResponse {
        pub transaction_id: u256,
        pub reinsurance_payment_id: u256,
        pub insured_proposal_id: u256,
        pub insured_policy_id: u256,
        pub claim_id: u256,
        pub insured: ContractAddress,
        pub reinsurer_id: u256,
        pub reinsurance_payment_address: ContractAddress,
        pub reinsurer_name: ByteArray,
        pub percentage_reinsurance: u16,
        pub gross_sum_insured: u256,
        pub ceded_sum_insured: u256,
        pub gross_premium: u256,
        pub ceded_premium: u256,
        pub gross_claim_amount: u256,
        pub reinsurance_claim_apportionment: u256,
        pub settlement_date: u64,
        pub updated_at: u64,
        pub txn_hash: felt252,
        pub reinsurance_doc_url: ByteArray,
        pub claim_discharge_voucher_url: ByteArray,
        pub settlement_status: PaymentStatus,
        pub reinsurance_status: ReinsuranceStatus
    }


    #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct Reinsurer {
        pub reinsurer_id: u256,
        pub reinsurer_name: ByteArray,
        pub reinsurer_head_office: ByteArray,
        pub reinsurer_fiat_account: ByteArray,
        pub reinsurer_web_site: ByteArray,
        pub risk_capacity: u256,
        pub contract_type_code: u8,
        pub total_obligation_offered: u256,
        pub total_obligation_fulfilled: u256,
        pub reliability_factor: u8,
        pub initial_contract_date: u64,
        pub last_contract_date: u64
    }


    #[derive(Drop, Serde, Clone)]
    pub struct ReinsurerResponse {
        pub reinsurer_id: u256,
        pub reinsurer_name: ByteArray,
        pub reinsurer_head_office: ByteArray,
        pub reinsurer_fiat_account: ByteArray,
        pub reinsurer_web_site: ByteArray,
        pub risk_capacity: u256,
        pub contract_type: ReinsuranceContractType,
        pub total_obligation_offered: u256,
        pub total_obligation_fulfilled: u256,
        pub reliability_factor: u8,
        pub initial_contract_date: u64,
        pub last_contract_date: u64
    }

