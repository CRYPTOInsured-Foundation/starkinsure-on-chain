#[starknet::contract]
pub mod ProposalFormContract {
use starknet::{ ContractAddress, ClassHash };
    use starknet::{ get_caller_address, get_block_timestamp };
//     use openzeppelin::token::erc20::interface::IERC20Dispatcher;
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use starknet::storage::{
        Map,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerWriteAccess,
        StoragePointerReadAccess
    };
    

    use crate::enums::enums::*;
    use crate::structs::structs::*;
    use crate::interfaces::interfaces::*;
    use crate::event_structs::event_structs::*;
    use crate::utils::utils::*;





    // Roles
    const UNDERWRITER_ROLE: felt252 = selector!("UNDERWRITER_ROLE");
    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");
    const RISK_OFFICER_ROLE: felt252 = selector!("RISK_OFFICER_ROLE");
    const PRICING_ACTUARY_ROLE: felt252 = selector!("PRICING_ACTUARY_ROLE");

    // Proposal statuses
    const STATUS_DRAFT: felt252 = selector!("STATUS_DRAFT");
    const STATUS_SUBMITTED: felt252 = selector!("STATUS_SUBMITTED");
    const STATUS_UNDER_REVIEW: felt252 = selector!("STATUS_UNDER_REVIEW");
    const STATUS_APPROVED: felt252 = selector!("STATUS_APPROVED");
    const STATUS_REJECTED: felt252 = selector!("STATUS_REJECTED");
    const STATUS_ACTIVE: felt252 = selector!("STATUS_ACTIVE");
    const STATUS_EXPIRED: felt252 = selector!("STATUS_EXPIRED");


    // Risk levels
    const RISK_LOW: felt252 = selector!("LOW_RISK");
    const RISK_MEDIUM: felt252 = selector!("MEDIUM_RISK");
    const RISK_HIGH: felt252 = selector!("HIGH_RISK");
    const RISK_EXTREME: felt252 = selector!("EXTREME_RISK");

    const ONE_DAY: u64 = 3600 * 24;


    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent);

    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;




            #[storage]
    pub struct Storage {
                #[substorage(v0)]
                accesscontrol: AccessControlComponent::Storage,
                #[substorage(v0)]
                src5: SRC5Component::Storage,
                #[substorage(v0)]
                upgradeable: UpgradeableComponent::Storage,
                #[substorage(v0)]
                reentrancyguard: ReentrancyGuardComponent::Storage,

                next_proposal_id: u256,
                proposals: Map<u256, ProposalForm>,
                min_coverage_amount: u256,
                max_coverage_amount: u256,
                min_premium_rate: u16,
                max_premium_rate: u16,    
                approved_proposals_count: u256,

                treasury_address: ContractAddress,
                policy_minting_address: ContractAddress,
                claims_contract_address: ContractAddress            
            }
    
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,


        ProposalCreated: ProposalCreated,
        ProposalUPdated: ProposalUpdated,
        ProposalRejected: ProposalRejected,
        ProposalApproved: ProposalApproved,
        PremiumPaymentSuccess: PremiumPaymentSuccess,
        ProposalExpired: ProposalExpired,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
    ) {
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(AccessControlComponent::DEFAULT_ADMIN_ROLE, admin);
        self.accesscontrol._grant_role(ADMIN_ROLE, admin);

        self.next_proposal_id.write(1);
    }

  
    #[abi(embed_v0)]
    pub impl ProposalFormImpl of IProposalForm<ContractState> {

        fn submit_proposal(
            ref self: ContractState,
            proposer: ContractAddress,
            policy_class_code: u8,
            subject_matter: ByteArray,
            sum_insured: u256,
            premium_frequency_code: u8,
            frequency_factor: u8,
        ) {

            let current_proposal_id: u256 = self.next_proposal_id.read();
            let current_date: u64 = get_block_timestamp();
            let seven_days: u64 = ONE_DAY * 7;

            let expiry_time: u64 = current_date + seven_days;

            let new_proposal: ProposalForm = ProposalForm {
                proposal_id: current_proposal_id,
                proposer: proposer,
                policy_class_code: policy_class_code,
                subject_matter: subject_matter,
                sum_insured: sum_insured,
                premium_payable: 0,
                premium_frequency_code: premium_frequency_code,
                frequency_factor: frequency_factor,
                has_kyc: false,
                submission_date: current_date,
                last_updated: current_date,
                expiration_date: expiry_time,
                is_active: true,
                is_expired: false,
                is_premium_paid: false,
                risk_analytics_approved: false,
                governance_approved: false,
                proposal_status_code: 1,
                rejection_reason_code: 8,
                risk_score: 0,
                premium_rate: 0,
                has_reinsurance: false,
                reinsurance_txn_id: 0,
            };

            self.proposals.write(current_proposal_id, new_proposal);


            let proposal_create_event: ProposalCreated = ProposalCreated {
                proposal_id: current_proposal_id,
                proposer: proposer,
                policy_class: convert_policy_code_to_class(policy_class_code),
                sum_insured: sum_insured
            };

            self.emit(proposal_create_event);        

            let new_proposal_id: u256 = current_proposal_id + 1;

            self.next_proposal_id.write(new_proposal_id);

        }

        fn update_proposal(
            ref self: ContractState,
            proposal_id: u256, 
            subject_matter: ByteArray,
            sum_insured: u256,
            premium_frequency_code: u8,
            frequency_factor: u8,
            has_reinsurance: bool,
            reinsurance_txn_id: u256
        ) {


            let updateable_proposal: ProposalForm = self.proposals.read(proposal_id);

            let current_time: u64 = get_block_timestamp();

            let set_expiry_time: u64 = updateable_proposal.expiration_date;

            assert!(current_time > set_expiry_time, "Unathorized: Proposal has expired");

            let updated_proposal: ProposalForm = ProposalForm {
                
                proposal_id: updateable_proposal.proposal_id,
                proposer: updateable_proposal.proposer,
                policy_class_code: updateable_proposal.policy_class_code,
                subject_matter: subject_matter,
                sum_insured: sum_insured,
                premium_payable: updateable_proposal.premium_payable,
                premium_frequency_code: premium_frequency_code,
                frequency_factor: frequency_factor,
                has_kyc: updateable_proposal.has_kyc,
                submission_date: updateable_proposal.submission_date,
                last_updated: current_time,
                expiration_date: updateable_proposal.expiration_date,
                is_active: updateable_proposal.is_active,
                is_expired: updateable_proposal.is_expired,
                is_premium_paid: updateable_proposal.is_premium_paid,
                risk_analytics_approved: updateable_proposal.risk_analytics_approved,
                governance_approved: updateable_proposal.governance_approved,
                proposal_status_code: updateable_proposal.proposal_status_code,
                rejection_reason_code: updateable_proposal.rejection_reason_code,
                risk_score: updateable_proposal.risk_score,
                premium_rate: updateable_proposal.premium_rate,
                has_reinsurance: has_reinsurance,
                reinsurance_txn_id: reinsurance_txn_id,
            };

            self.proposals.write(proposal_id, updated_proposal);

            let proposal_update_event: ProposalUpdated = ProposalUpdated {
                proposal_id: proposal_id,
                proposer: updateable_proposal.proposer,
                policy_class: convert_policy_code_to_class(updateable_proposal.policy_class_code),
                sum_insured: sum_insured,
                last_updated: current_time
            };

            self.emit(proposal_update_event);

        }

        fn get_proposal_by_id(
            self: @ContractState,
            proposal_id: u256
        ) -> ProposalFormResponse{

            let proposal: ProposalForm = self.proposals.read(proposal_id);

            let response_obj: ProposalFormResponse = ProposalFormResponse {
                proposal_id: proposal_id,
                proposer: proposal.proposer,
                policy_class: convert_policy_code_to_class(proposal.policy_class_code),
                subject_matter: proposal.subject_matter,
                sum_insured: proposal.sum_insured,
                premium_payable: proposal.premium_payable,
                premium_frequency: convert_premium_code_to_frequency(proposal.premium_frequency_code),
                frequency_factor: proposal.frequency_factor,
                has_kyc: proposal.has_kyc,
                submission_date: proposal.submission_date,
                last_updated: proposal.last_updated,
                expiration_date: proposal.expiration_date,
                is_active: proposal.is_active,
                is_expired: proposal.is_expired,
                is_premium_paid: proposal.is_premium_paid,
                risk_analytics_approved: proposal.risk_analytics_approved,
                governance_approved: proposal.governance_approved,
                proposal_status: convert_proposal_code_to_status(proposal.proposal_status_code),
                rejection_reason: convert_rejection_code_to_reason(proposal.rejection_reason_code),
                risk_score: proposal.risk_score,
                premium_rate: proposal.premium_rate,
                has_reinsurance: proposal.has_reinsurance,
                reinsurance_txn_id: proposal.reinsurance_txn_id,
            };

            response_obj

        }

        fn get_min_premium_rate(
            self: @ContractState
        ) -> u16 {
            self.min_premium_rate.read()
        }

        fn set_min_premium_rate(
            ref self: ContractState,
            new_rate: u16
        ) {
            let approver_address: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, approver_address), "AccessControl: Caller is not the Admin");

            self.min_premium_rate.write(new_rate);
        }

        fn get_max_premium_rate(
            self: @ContractState
        ) -> u16{
            self.max_premium_rate.read()
        }

        fn set_max_premium_rate(
            ref self: ContractState,
            new_rate: u16
        ) {
            let approver_address: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, approver_address), "AccessControl: Caller is not the Admin");

            self.max_premium_rate.write(new_rate);
        }

        fn get_min_coverage_amount(
            self: @ContractState
        ) -> u256 {
            self.min_coverage_amount.read()
        }

        fn set_min_coverage_amount(
            ref self: ContractState,
            new_amount: u256
        ){ 
            let approver_address: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, approver_address), "AccessControl: Caller is not the Admin");

            self.min_coverage_amount.write(new_amount);
        }

        fn get_max_coverage_amount(
            self: @ContractState
        ) -> u256 {
            self.max_coverage_amount.read()
        }

        fn set_max_coverage_amount(
            ref self: ContractState,
            new_amount: u256
        ){ 
            let approver_address: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, approver_address), "AccessControl: Caller is not the Admin");

            self.max_coverage_amount.write(new_amount);
        }


        fn assess_proposal_by_risk_service(
            ref self: ContractState,
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
        ) {

            let approver_address: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, approver_address), "AccessControl: Caller is not the Admin");

            let updateable_proposal: ProposalForm = self.proposals.read(proposal_id);


            let updated_proposal: ProposalForm = ProposalForm {
                
                proposal_id: updateable_proposal.proposal_id,
                proposer: updateable_proposal.proposer,
                policy_class_code: updateable_proposal.policy_class_code,
                subject_matter: updateable_proposal.subject_matter,
                sum_insured: updateable_proposal.sum_insured,
                premium_payable: premium_payable,
                premium_frequency_code: updateable_proposal.premium_frequency_code,
                frequency_factor: updateable_proposal.frequency_factor,
                has_kyc: has_kyc,
                submission_date: updateable_proposal.submission_date,
                last_updated: updateable_proposal.last_updated,
                expiration_date: updateable_proposal.expiration_date,
                is_active: updateable_proposal.is_active,
                is_expired: updateable_proposal.is_expired,
                is_premium_paid: updateable_proposal.is_premium_paid,
                risk_analytics_approved: risk_analytics_approved,
                governance_approved: updateable_proposal.governance_approved,
                proposal_status_code: proposal_status_code,
                rejection_reason_code: rejection_reason_code,
                risk_score: risk_score,
                premium_rate: premium_rate,
                has_reinsurance: has_reinsurance,
                reinsurance_txn_id: reinsurance_txn_id,

            };

            self.proposals.write(proposal_id, updated_proposal);


            if risk_analytics_approved  {

                let approval_event: ProposalApproved = ProposalApproved {
                    proposal_id: proposal_id,
                    proposer: updateable_proposal.proposer,
                    approver: approver_address,
                    premium_payable: premium_payable,
                    premium_rate: premium_rate
                };

                self.emit(approval_event);
               
            } else {

                let rejection_event: ProposalRejected = ProposalRejected {
                    proposal_id: proposal_id,
                    proposer: updateable_proposal.proposer,
                    rejector: approver_address,
                    reason: convert_rejection_code_to_reason(rejection_reason_code)
                };

                self.emit(rejection_event);

            }

        }
    
        fn assess_proposal_by_governance(
            ref self: ContractState,
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
        ) {

            let approver_address: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, approver_address), "AccessControl: Caller is not the Admin");

            let updateable_proposal: ProposalForm = self.proposals.read(proposal_id);

            let updated_proposal: ProposalForm = ProposalForm {
                
                proposal_id: updateable_proposal.proposal_id,
                proposer: updateable_proposal.proposer,
                policy_class_code: updateable_proposal.policy_class_code,
                subject_matter: updateable_proposal.subject_matter,
                sum_insured: updateable_proposal.sum_insured,
                premium_payable: premium_payable,
                premium_frequency_code: updateable_proposal.premium_frequency_code,
                frequency_factor: updateable_proposal.frequency_factor,
                has_kyc: has_kyc,
                submission_date: updateable_proposal.submission_date,
                last_updated: updateable_proposal.last_updated,
                expiration_date: updateable_proposal.expiration_date,
                is_active: updateable_proposal.is_active,
                is_expired: updateable_proposal.is_expired,
                is_premium_paid: updateable_proposal.is_premium_paid,
                risk_analytics_approved: updateable_proposal.risk_analytics_approved,
                governance_approved: governance_approved,
                proposal_status_code: proposal_status_code,
                rejection_reason_code: rejection_reason_code,
                risk_score: risk_score,
                premium_rate: premium_rate,
                has_reinsurance: has_reinsurance,
                reinsurance_txn_id: reinsurance_txn_id,
            };

            self.proposals.write(proposal_id, updated_proposal);


            if governance_approved  {

                let approval_event: ProposalApproved = ProposalApproved {
                    proposal_id: proposal_id,
                    proposer: updateable_proposal.proposer,
                    approver: approver_address,
                    premium_payable: premium_payable,
                    premium_rate: premium_rate
                };

                self.emit(approval_event);
               
            } else {

                let rejection_event: ProposalRejected = ProposalRejected {
                    proposal_id: proposal_id,
                    proposer: updateable_proposal.proposer,
                    rejector: approver_address,
                    reason: convert_rejection_code_to_reason(rejection_reason_code)
                };

                self.emit(rejection_event);

            }            
        }


        fn set_treasury_address(
            ref self: ContractState,
            treasury_address: ContractAddress
        ){
            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
            self.treasury_address.write(treasury_address);
        }
    
        fn set_policy_minting_address(
            ref self: ContractState,
            policy_minting_address: ContractAddress
        ) {
            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
            self.policy_minting_address.write(policy_minting_address);
        }
    
        fn set_claims_contract_address(
            ref self: ContractState,
            claims_contract_address: ContractAddress
        ) {
            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
            self.claims_contract_address.write(claims_contract_address);
        }
    }


    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {

            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");

            self.upgradeable.upgrade(new_class_hash);
        }
    }
}
