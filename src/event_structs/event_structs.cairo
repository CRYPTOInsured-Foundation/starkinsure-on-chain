use crate::enums::enums::ClaimsPaymentSource;
use starknet::ContractAddress;
use crate::enums::enums::*;


#[derive(Drop, starknet::Event)]
    pub struct PolicyUpdated {
        #[key]
        pub token_id: u256,
        pub sum_insured: u256,
        pub premium: u256,
        pub endorsement_amount: u256,
        pub expiration_date: u64,
        pub subject_matter: ByteArray,
        pub update_type: UpdateType
    }


    #[derive(Drop, starknet::Event)]
    pub struct PolicyMinted {
        #[key]
        pub token_id: u256,
        pub policyholder: ContractAddress,
        pub policy_class: PolicyClass,
        pub subject_matter: ByteArray,
        pub sum_insured: u256,
        pub premium: u256,
        pub premium_frequency: PremiumFrequency,
        pub frequency_factor: u8,
        pub minter: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PolicyBurned {
        pub burner: ContractAddress,
        pub token_id: u256,
        pub reason: BurnReason
    }



#[derive(Drop, starknet::Event)]
pub struct ProposalCreated {
    #[key]
    pub proposal_id: u256,
    pub proposer: ContractAddress,
    pub policy_class: PolicyClass,
    pub sum_insured: u256
}


#[derive(Drop, starknet::Event)]
pub struct ProposalUpdated {
    #[key]
    pub proposal_id: u256,
    pub proposer: ContractAddress,
    pub policy_class: PolicyClass,
    pub sum_insured: u256,
    pub last_updated: u64
}



#[derive(Drop, starknet::Event)]
pub struct ProposalApproved {
    #[key]
    pub proposal_id: u256,
    pub proposer: ContractAddress,
    pub approver: ContractAddress,
    pub premium_payable: u256,
    pub premium_rate: u16,
}

#[derive(Drop, starknet::Event)]
pub struct ProposalRejected {
    #[key]
    pub proposal_id: u256,
    pub proposer: ContractAddress,
    pub rejector: ContractAddress,
    pub reason: RejectionReason
}


#[derive(Drop, starknet::Event)]
pub struct PremiumPaymentSuccess {
    #[key]
    pub proposal_id: u256,
    pub policyholder: ContractAddress,
    pub payer: ContractAddress,
    pub amount: u256,
    pub policy_token_id:u256,
    pub policy_id: u256
}

#[derive(Drop, starknet::Event)]
pub struct ProposalExpired {
    #[key]
    pub proposal_id: u256,
    pub proposer: ContractAddress,
    pub policy_class: PolicyClass,
    pub expired_at: u64
}



    #[derive(Drop, starknet::Event)]
    pub struct ClaimSubmitted {
        #[key]
        pub claim_id: u256,
        pub policy_id: u256,
        pub claimant: ContractAddress,
        pub amount: u256,
        pub claim_type: ClaimType
    }


    #[derive(Drop, starknet::Event)]
    pub struct ClaimUpdated {
        #[key]
        pub claim_id: u256,
        pub policy_id: u256,
        pub claimant: ContractAddress,
        pub amount: u256,
        pub claim_type: ClaimType
    }

    #[derive(Drop, starknet::Event)]
    pub struct ClaimApproved {
        #[key]
        pub claim_id: u256,
        pub approver: ContractAddress,
        pub amount: u256,
        pub timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    pub struct ClaimRepudiated {
        #[key]
        pub claim_id: u256,
        pub denier: ContractAddress,
        pub reason: ClaimRepudiationReason
    }

    #[derive(Drop, starknet::Event)]
    pub struct ClaimPaid {
        #[key]
        pub claim_id: u256,
        pub recipient: ContractAddress,
        pub amount: u256,
        pub tx_hash: felt252
    }

    #[derive(Drop, starknet::Event)]
    pub struct ClaimEscalated {
        #[key]
        pub claim_id: u256,
        pub escalator: ContractAddress,
        pub reason: ByteArray,
    }



#[derive(Drop, starknet::Event)]
pub struct PremiumPaymentRecorded {
    #[key]
    pub transaction_id: u256,
    pub proposal_id: u256,
    pub policy_id: u256,
    pub payer_address: ContractAddress,
    pub policyholder: ContractAddress,
    pub amount_paid: u256,
    pub sum_insured: u256,
    pub payment_date: u64,
    pub txn_hash: felt252
}

#[derive(Drop, starknet::Event)]
pub struct PremiumPaymentUpdated {
    #[key]
    pub transaction_id: u256,
    pub policy_id: u256,
    pub txn_hash: felt252,
    pub payment_status: PaymentStatus,
    pub updated_at: u64
}


#[derive(Drop, starknet::Event)]
pub struct ClaimPaymentExecuted {
    #[key]
    pub transaction_id: u256,
    pub policy_id: u256,
    pub claim_id: u256,
    pub policyholder: ContractAddress,
    pub third_party_account: ContractAddress,
    pub claim_amount: u256,
    pub approved_settlement_amount: u256,
    pub settlement_date: u64,
    pub txn_hash: felt252,
    pub settlement_source: ClaimsPaymentSource
}

#[derive(Drop, starknet::Event)]
pub struct ClaimPaymentUpdated {
    #[key]
    pub transaction_id: u256,
    pub policy_id: u256,
    pub claim_id: u256,
    pub policyholder: ContractAddress,
    pub third_party_account: ContractAddress,
    pub settlement_status: PaymentStatus,
    pub settlement_source: ClaimsPaymentSource,
    pub updated_at: u64,
    pub txn_hash: felt252
}

// STINDEM Purchase Events
#[derive(Drop, starknet::Event)]
pub struct StindemPurchased {
    #[key]
    pub transaction_id: u256,
    pub buyer_address: ContractAddress,
    pub seller_address: ContractAddress,
    pub token_address: ContractAddress,
    pub quantity: u256,
    pub unit_price: u256,
    pub total_price_paid: u256,
    pub payment_date: u64,
    pub txn_hash: felt252
}

#[derive(Drop, starknet::Event)]
pub struct StindemPurchaseUpdated {
    #[key]
    pub transaction_id: u256,
    pub buyer_address: ContractAddress,
    pub token_address: ContractAddress,
    pub quantity: u256,
    pub payment_status: PaymentStatus,
    pub updated_at: u64,
    pub txn_hash: felt252
}

// STINDEM Recovery Events
#[derive(Drop, starknet::Event)]
pub struct StindemRecovered {
    #[key]
    pub transaction_id: u256,
    pub seller_address: ContractAddress,
    pub buyer_address: ContractAddress,
    pub stindem_token_address: ContractAddress,
    pub strk_token_address: ContractAddress,
    pub stindem_quantity: u256,
    pub strk_amount_paid: u256,
    pub unit_price: u256,
    pub recovery_date: u64,
    pub txn_hash: felt252
}

#[derive(Drop, starknet::Event)]
pub struct StindemRecoveryUpdated {
    #[key]
    pub transaction_id: u256,
    pub seller_address: ContractAddress,
    pub stindem_quantity: u256,
    pub strk_amount_paid: u256,
    pub payment_status: PaymentStatus,
    pub updated_at: u64,
    pub txn_hash: felt252
}

// Voting Commitment Events
#[derive(Drop, starknet::Event)]
pub struct VotingCommitmentPurchased {
    #[key]
    pub transaction_id: u256,
    pub voter_address: ContractAddress,
    pub treasury_address: ContractAddress,
    pub stindem_token_address: ContractAddress,
    pub stindem_quantity: u256,
    pub unit_price: u256,
    pub commitment_date: u64,
    pub txn_hash: felt252
}

#[derive(Drop, starknet::Event)]
pub struct VotingCommitmentUpdated {
    #[key]
    pub transaction_id: u256,
    pub voter_address: ContractAddress,
    pub stindem_quantity: u256,
    pub payment_status: PaymentStatus,
    pub updated_at: u64,
    pub txn_hash: felt252
}




   