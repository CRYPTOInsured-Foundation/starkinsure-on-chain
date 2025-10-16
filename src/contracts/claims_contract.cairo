#[starknet::contract]
mod InsuranceClaims {

use starknet::{
        ContractAddress,
        ClassHash,
        get_caller_address,
        get_block_timestamp
    };

    use starknet::storage::{
        Map,
        Vec,
        VecTrait,
        MutableVecTrait,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess,
        StoragePathEntry
    };

    use core::traits::{
        Into,
    };

    use crate::structs::structs::*;
    use crate::enums::enums::*;
    use crate::event_structs::event_structs::*;
    use crate::utils::utils::*;
    use crate::interfaces::interfaces::*;




//     use openzeppelin::token::erc20::interface::IERC20Dispatcher;
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;


    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);


    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;


    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // Roles
    const CLAIM_ADJUSTER_ROLE: felt252 = selector!("CLAIM_ADJUSTER_ROLE");
    const CLAIM_APPROVER_ROLE: felt252 = selector!("CLAIM_APPROVER_ROLE");
    const EMERGENCY_MANAGER_ROLE: felt252 = selector!("EMERGENCY_MANAGER_ROLE");
    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");




           #[storage]
    struct Storage {
//         // OpenZeppelin Components
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,


        // Claims Map by claim_id and claim_object
        next_claim_id: u256,
        claims: Map<u256, InsuranceClaim>,
        claims_vec: Vec<InsuranceClaim>,
        settled_claims: Vec<InsuranceClaim>,
        repudiated_claims: Vec<InsuranceClaim>,
        escalated_claims: Vec<InsuranceClaim>,
        //Claim Evidences by Claim ID and Array of Proof Urls
        claim_evidences: Map<u256, Vec<ByteArray>>,
        treasury_address: ContractAddress,
        governance_address: ContractAddress,
        proposal_form_address: ContractAddress,
        policy_minting_address: ContractAddress,

        auto_approval_limit: u256,
        max_claim_amount_payable: u256,
        number_of_approved_claims: u256,
        number_of_repudiated_claims: u256,
        amount_of_approved_claims: u256,
        amount_of_repudiated_claims: u256
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,

        ClaimSubmitted: ClaimSubmitted,
        ClaimUpdated: ClaimUpdated,
        ClaimDenied: ClaimRepudiated,
        ClaimApproved: ClaimApproved,
        ClaimPaid: ClaimPaid,
        ClaimEscalated: ClaimEscalated
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin_address: ContractAddress,
    ) {

        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(AccessControlComponent::DEFAULT_ADMIN_ROLE, admin_address);
        self.accesscontrol._grant_role(ADMIN_ROLE, admin_address);
        self.next_claim_id.write(1);
    }


    #[abi(embed_v0)]
    pub impl InsuranceClaimsImpl of IClaim<ContractState> {
        fn file_claim(
            ref self: ContractState,
            policy_id: u256,
            claimant: ContractAddress,
            claim_description: ByteArray,
            claim_amount: u256,
            alternative_account: ContractAddress,
            policy_class_code: u8,
            proof_urls: Array<ByteArray>
        ) -> u256 {

            let current_claim_id: u256 = self.next_claim_id.read();
            let current_date: u64 = get_block_timestamp();
            
            let policy_mint_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher { contract_address: self.policy_minting_address.read() };
            
            let claimant_policy: PolicyDataResponse = policy_mint_dispatcher.get_policy_data(policy_id);

            let claimant_from_policy: ContractAddress = claimant_policy.policyholder;

            assert!(claimant == claimant_from_policy, "Unauthorized: Claimant Address does not match with Policyholder Address on Policy Data");


            let proof_urls_length: u32 = proof_urls.len().into();

            for i in 0..proof_urls_length {

                let mut my_byte_array: ByteArray = proof_urls.at(i).clone();      
                self.claim_evidences.entry(current_claim_id).push(my_byte_array);

            }



            let new_claim: InsuranceClaim = InsuranceClaim {
                claim_id: current_claim_id,
                policy_id: policy_id,
                proposal_id: claimant_policy.proposal_id,
                claimant: claimant,
                claim_description: claim_description,
                claim_amount: claim_amount,
                approved_settlement_amount: 0,
                alternative_account: alternative_account,
                policy_class_code: policy_class_code,
                claim_status_code: 0,
                claim_type_code: 4,
                submission_date: current_date,
                updated_at: current_date,
                is_approved: false,
                approved_at: 0,
                is_repudiated: false,
                repudiated_at: 0,
                risk_analytics_approved: false,
                governance_approved: false,
                is_escalated: false,
                escalation_reason: "",
                repudiation_reason_code: 100
            };

            policy_mint_dispatcher.add_claim_to_policy(policy_id, current_claim_id, claim_amount);

            self.claims_vec.push(new_claim.clone());

            self.claims.write(current_claim_id, new_claim);

            let incremented_claim_id: u256 = current_claim_id + 1;

            self.next_claim_id.write(incremented_claim_id);

            let submission_event: ClaimSubmitted = ClaimSubmitted {
                claim_id: current_claim_id,
                policy_id: policy_id,
                claimant: claimant,
                amount: claim_amount,
                claim_type: ClaimType::Undetermined
            };

            self.emit(submission_event);

            current_claim_id
        }
    
        fn update_claim(
            ref self: ContractState,
            claim_id: u256,
            policy_id: u256,
            claimant: ContractAddress,
            claim_description: ByteArray,
            claim_amount: u256,
            alternative_account: ContractAddress,
            policy_class_code: u8,
            proof_urls: Array<ByteArray>
        ) {

            let current_date: u64 = get_block_timestamp();

            let claim_to_update: InsuranceClaim = self.claims.read(claim_id);
            
            let policy_mint_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher { contract_address: self.policy_minting_address.read() };
            
            let claimant_policy: PolicyDataResponse = policy_mint_dispatcher.get_policy_data(policy_id);

            let claimant_from_policy: ContractAddress = claimant_policy.policyholder;

            assert!(claimant == claimant_from_policy, "Unauthorized: Claimant Account Address does not match with Policyholder Account Address on Policy Data");


            let proof_urls_length: u32 = proof_urls.len().into();

            for i in 0..proof_urls_length {

                let mut my_byte_array: ByteArray = proof_urls.at(i).clone();      
                self.claim_evidences.entry(claim_to_update.claim_id).push(my_byte_array);
                
            }


            let updated_claim: InsuranceClaim = InsuranceClaim {
                claim_id: claim_to_update.claim_id,
                policy_id: policy_id,
                proposal_id: claimant_policy.proposal_id,
                claimant: claimant,
                claim_description: claim_description,
                claim_amount: claim_amount,
                approved_settlement_amount: claim_to_update.approved_settlement_amount,
                alternative_account: alternative_account,
                policy_class_code: policy_class_code,
                claim_status_code: claim_to_update.claim_status_code,
                claim_type_code: claim_to_update.claim_type_code,
                submission_date: claim_to_update.submission_date,
                updated_at: current_date,
                is_approved: claim_to_update.is_approved,
                approved_at: claim_to_update.approved_at,
                is_repudiated: claim_to_update.is_repudiated,
                repudiated_at: claim_to_update.repudiated_at,
                risk_analytics_approved: claim_to_update.risk_analytics_approved,
                governance_approved: claim_to_update.governance_approved,
                is_escalated: claim_to_update.is_escalated,
                escalation_reason: claim_to_update.escalation_reason,
                repudiation_reason_code: claim_to_update.repudiation_reason_code
            };


            self.claims.write(claim_to_update.claim_id, updated_claim);

            let update_event: ClaimUpdated = ClaimUpdated {
                claim_id: claim_to_update.claim_id,
                policy_id: claim_to_update.policy_id,
                claimant: claim_to_update.claimant,
                amount: claim_to_update.claim_amount,
                claim_type: convert_claim_code_to_type(claim_to_update.claim_type_code)
            };

            self.emit(update_event);

        }
    
        fn get_claim_by_id(
            self: @ContractState,
            claim_id: u256
        ) -> InsuranceClaimResponse {

            let sought_claim: InsuranceClaim = self.claims.read(claim_id);

            let mut proof_urls: Array<ByteArray> = array![];

            let len: u64 = self.claim_evidences.entry(sought_claim.claim_id).len();

            for i in 0..len {
                let mut each_url: ByteArray = self.claim_evidences.entry(sought_claim.claim_id).at(i).read();
                proof_urls.append(each_url);
            }

            let claim_response: InsuranceClaimResponse = InsuranceClaimResponse {
                claim_id: sought_claim.claim_id,
                policy_id: sought_claim.policy_id,
                proposal_id: sought_claim.proposal_id,
                claimant: sought_claim.claimant,
                claim_description: sought_claim.claim_description,
                claim_amount: sought_claim.claim_amount,
                approved_settlement_amount: sought_claim.approved_settlement_amount,
                alternative_account: sought_claim.alternative_account,
                policy_class: convert_policy_code_to_class(sought_claim.policy_class_code),
                claim_status: convert_claim_code_to_status(sought_claim.claim_status_code),
                claim_type: convert_claim_code_to_type(sought_claim.claim_type_code),
                submission_date: sought_claim.submission_date,
                updated_at: sought_claim.updated_at,
                is_approved: sought_claim.is_approved,
                approved_at: sought_claim.approved_at,
                is_repudiated: sought_claim.is_repudiated,
                repudiated_at: sought_claim.repudiated_at,
                risk_analytics_approved: sought_claim.risk_analytics_approved,
                governance_approved: sought_claim.governance_approved,
                is_escalated: sought_claim.is_escalated,
                escalation_reason: sought_claim.escalation_reason,
                claim_evidence_urls: proof_urls,
                repudiation_reason: convert_repudiation_code_to_reason(sought_claim.repudiation_reason_code)
            };

            claim_response
        }

        fn get_claim_evidence_urls_for_current_claim(
            self: @ContractState,
            claim_id: u256
        ) -> Array<ByteArray> {


            let sought_claim: InsuranceClaim = self.claims.read(claim_id);
            
            let mut proof_urls: Array<ByteArray> = array![];

            let len: u64 = self.claim_evidences.entry(sought_claim.claim_id).len();

            for i in 0..len {
                let mut each_url: ByteArray = self.claim_evidences.entry(sought_claim.claim_id).at(i).read();
                proof_urls.append(each_url);
            }

            proof_urls
        }
    
        fn assess_claim_by_risk_analytics(
            ref self: ContractState,
            claim_id: u256,
            risk_analytics_approved: bool,
            is_approved: bool,
            is_repudiated: bool,
            repudiation_reason_code: u8,
            claim_status_code: u8,
            claim_type_code: u8,
            approved_settlement_amount: u256,
        ) {

            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");


            let current_date: u64 = get_block_timestamp();

            let claim_to_assess: InsuranceClaim = self.claims.read(claim_id);
            
            let policy_mint_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher { contract_address: self.policy_minting_address.read() };
            
            let claimant_policy: PolicyDataResponse = policy_mint_dispatcher.get_policy_data(claim_to_assess.policy_id);

            let claimant_from_policy: ContractAddress = claimant_policy.policyholder;

            let claimant: ContractAddress = claim_to_assess.claimant;

            assert!(claimant == claimant_from_policy, "Unauthorized: Claimant Address does not match with Policyholder Address on Policy Data");

            let assessed_claim: InsuranceClaim = InsuranceClaim {
                claim_id: claim_to_assess.claim_id,
                policy_id: claim_to_assess.policy_id,
                proposal_id: claimant_policy.proposal_id,
                claimant: claimant,
                claim_description: claim_to_assess.claim_description,
                claim_amount: claim_to_assess.claim_amount,
                approved_settlement_amount: approved_settlement_amount,
                alternative_account: claim_to_assess.alternative_account,
                policy_class_code: claim_to_assess.policy_class_code,
                claim_status_code: claim_status_code,
                claim_type_code: claim_type_code,
                submission_date: claim_to_assess.submission_date,
                updated_at: claim_to_assess.updated_at,
                is_approved: is_approved,
                approved_at: current_date,
                is_repudiated: is_repudiated,
                repudiated_at: current_date,
                risk_analytics_approved: risk_analytics_approved,
                governance_approved: claim_to_assess.governance_approved,
                is_escalated: claim_to_assess.is_escalated,
                escalation_reason: claim_to_assess.escalation_reason,
                repudiation_reason_code: repudiation_reason_code
            };

            self.claims.write(claim_to_assess.claim_id, assessed_claim);
        }
    
        fn assess_claim_by_governance(
            ref self: ContractState,
            claim_id: u256,
            governance_approved: bool,
            is_approved: bool,
            is_repudiated: bool,
            repudiation_reason_code: u8,
            claim_status_code: u8,
            claim_type_code: u8,
            approved_settlement_amount: u256,
        ) {

            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");


            let current_date: u64 = get_block_timestamp();

            let claim_to_assess: InsuranceClaim = self.claims.read(claim_id);
            
            let policy_mint_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher { contract_address: self.policy_minting_address.read() };
            
            let claimant_policy: PolicyDataResponse = policy_mint_dispatcher.get_policy_data(claim_to_assess.policy_id);

            let claimant_from_policy: ContractAddress = claimant_policy.policyholder;

            let claimant: ContractAddress = claim_to_assess.claimant;

            assert!(claimant == claimant_from_policy, "Unauthorized: Claimant Address does not match with Policyholder Address on Policy Data");

            let assessed_claim: InsuranceClaim = InsuranceClaim {
                claim_id: claim_to_assess.claim_id,
                policy_id: claim_to_assess.policy_id,
                proposal_id: claimant_policy.proposal_id,
                claimant: claimant,
                claim_description: claim_to_assess.claim_description,
                claim_amount: claim_to_assess.claim_amount,
                approved_settlement_amount: approved_settlement_amount,
                alternative_account: claim_to_assess.alternative_account,
                policy_class_code: claim_to_assess.policy_class_code,
                claim_status_code: claim_status_code,
                claim_type_code: claim_type_code,
                submission_date: claim_to_assess.submission_date,
                updated_at: claim_to_assess.updated_at,
                is_approved: is_approved,
                approved_at: current_date,
                is_repudiated: is_repudiated,
                repudiated_at: current_date,
                risk_analytics_approved: claim_to_assess.risk_analytics_approved,
                governance_approved: governance_approved,
                is_escalated: claim_to_assess.is_escalated,
                escalation_reason: claim_to_assess.escalation_reason,
                repudiation_reason_code: repudiation_reason_code
            };

            self.claims.write(claim_to_assess.claim_id, assessed_claim);
        }


        fn set_claim_as_settled(
            ref self: ContractState,
            claim_id: u256
        ) {

            let mut sought_claim: InsuranceClaim = self.claims.read(claim_id);

            let settled_claim: InsuranceClaim = InsuranceClaim {
                claim_id: sought_claim.claim_id,
                policy_id: sought_claim.policy_id,
                proposal_id: sought_claim.proposal_id,
                claimant: sought_claim.claimant,
                claim_description: sought_claim.claim_description,
                claim_amount: sought_claim.claim_amount,
                approved_settlement_amount: sought_claim.approved_settlement_amount,
                alternative_account: sought_claim.alternative_account,
                policy_class_code: sought_claim.policy_class_code,
                claim_status_code: convert_claim_status_to_code(ClaimStatus::Settled),
                claim_type_code: sought_claim.claim_type_code,
                submission_date: sought_claim.submission_date,
                updated_at: sought_claim.updated_at,
                is_approved: sought_claim.is_approved,
                approved_at: sought_claim.approved_at,
                is_repudiated: sought_claim.is_repudiated,
                repudiated_at: sought_claim.repudiated_at,
                risk_analytics_approved: sought_claim.risk_analytics_approved,
                governance_approved: sought_claim.governance_approved,
                is_escalated: sought_claim.is_escalated,
                escalation_reason: sought_claim.escalation_reason,
                repudiation_reason_code: sought_claim.repudiation_reason_code

            };


            self.claims.write(sought_claim.claim_id, settled_claim.clone());
            self.settled_claims.push(settled_claim);
        }
    
        fn set_claim_as_repudiated(
            ref self: ContractState,
            claim_id: u256
        ) {

            let mut sought_claim: InsuranceClaim = self.claims.read(claim_id);

            let repudiated_claim: InsuranceClaim = InsuranceClaim {
                claim_id: sought_claim.claim_id,
                policy_id: sought_claim.policy_id,
                proposal_id: sought_claim.proposal_id,
                claimant: sought_claim.claimant,
                claim_description: sought_claim.claim_description,
                claim_amount: sought_claim.claim_amount,
                approved_settlement_amount: sought_claim.approved_settlement_amount,
                alternative_account: sought_claim.alternative_account,
                policy_class_code: sought_claim.policy_class_code,
                claim_status_code: convert_claim_status_to_code(ClaimStatus::Repudiated),
                claim_type_code: sought_claim.claim_type_code,
                submission_date: sought_claim.submission_date,
                updated_at: sought_claim.updated_at,
                is_approved: sought_claim.is_approved,
                approved_at: sought_claim.approved_at,
                is_repudiated: sought_claim.is_repudiated,
                repudiated_at: sought_claim.repudiated_at,
                risk_analytics_approved: sought_claim.risk_analytics_approved,
                governance_approved: sought_claim.governance_approved,
                is_escalated: sought_claim.is_escalated,
                escalation_reason: sought_claim.escalation_reason,
                repudiation_reason_code: sought_claim.repudiation_reason_code

            };


            self.claims.write(sought_claim.claim_id, repudiated_claim.clone());
            self.repudiated_claims.push(repudiated_claim);

        }
    
        fn get_settled_claims(
            self: @ContractState
        ) -> Array<InsuranceClaimResponse> {


            let mut response_array: Array<InsuranceClaimResponse> = array![];

            let len: u64 = self.settled_claims.len().into();

            for i in 0..len {

                let desired_claim: InsuranceClaim = self.settled_claims.at(i).read();

                let proof_urls: Array<ByteArray> = self._get_claim_evidence_urls_for_current_claim(desired_claim.claim_id);

                

                let each_response_obj: InsuranceClaimResponse = InsuranceClaimResponse {
                    claim_id: desired_claim.claim_id,
                    policy_id: desired_claim.policy_id,
                    proposal_id: desired_claim.proposal_id,
                    claimant: desired_claim.claimant,
                    claim_description: desired_claim.claim_description,
                    claim_amount: desired_claim.claim_amount,
                    approved_settlement_amount: desired_claim.approved_settlement_amount,
                    alternative_account: desired_claim.alternative_account,
                    policy_class: convert_policy_code_to_class(desired_claim.policy_class_code),
                    claim_status: convert_claim_code_to_status(desired_claim.claim_status_code),
                    claim_type: convert_claim_code_to_type(desired_claim.claim_type_code),
                    submission_date: desired_claim.submission_date,
                    updated_at: desired_claim.updated_at,
                    is_approved: desired_claim.is_approved,
                    approved_at: desired_claim.approved_at,
                    is_repudiated: desired_claim.is_repudiated,
                    repudiated_at: desired_claim.repudiated_at,
                    risk_analytics_approved: desired_claim.risk_analytics_approved,
                    governance_approved: desired_claim.governance_approved,
                    is_escalated: desired_claim.is_escalated,
                    escalation_reason: desired_claim.escalation_reason.clone(),
                    claim_evidence_urls: proof_urls,
                    repudiation_reason: convert_repudiation_code_to_reason(desired_claim.repudiation_reason_code)
                };

                response_array.append(each_response_obj);
               
             
            };

            response_array

        }
    
        fn get_repudiated_claims(
            self: @ContractState
        ) -> Array<InsuranceClaimResponse> {

            let mut response_array: Array<InsuranceClaimResponse> = array![];

            let len: u64 = self.repudiated_claims.len().into();

            for i in 0..len {

                let desired_claim: InsuranceClaim = self.repudiated_claims.at(i).read();

                let proof_urls: Array<ByteArray> = self._get_claim_evidence_urls_for_current_claim(desired_claim.claim_id);

                

                let each_response_obj: InsuranceClaimResponse = InsuranceClaimResponse {
                    claim_id: desired_claim.claim_id,
                    policy_id: desired_claim.policy_id,
                    proposal_id: desired_claim.proposal_id,
                    claimant: desired_claim.claimant,
                    claim_description: desired_claim.claim_description,
                    claim_amount: desired_claim.claim_amount,
                    approved_settlement_amount: desired_claim.approved_settlement_amount,
                    alternative_account: desired_claim.alternative_account,
                    policy_class: convert_policy_code_to_class(desired_claim.policy_class_code),
                    claim_status: convert_claim_code_to_status(desired_claim.claim_status_code),
                    claim_type: convert_claim_code_to_type(desired_claim.claim_type_code),
                    submission_date: desired_claim.submission_date,
                    updated_at: desired_claim.updated_at,
                    is_approved: desired_claim.is_approved,
                    approved_at: desired_claim.approved_at,
                    is_repudiated: desired_claim.is_repudiated,
                    repudiated_at: desired_claim.repudiated_at,
                    risk_analytics_approved: desired_claim.risk_analytics_approved,
                    governance_approved: desired_claim.governance_approved,
                    is_escalated: desired_claim.is_escalated,
                    escalation_reason: desired_claim.escalation_reason.clone(),
                    claim_evidence_urls: proof_urls,
                    repudiation_reason: convert_repudiation_code_to_reason(desired_claim.repudiation_reason_code)
                };

                response_array.append(each_response_obj);
               
             
            };

            response_array

        }
    
        fn get_pending_claims(
            self: @ContractState
        ) -> Array<InsuranceClaimResponse> {

            let mut response_array: Array<InsuranceClaimResponse> = array![];

            let pending_claims_array: Array<InsuranceClaim> = self._filter_out_settled_and_repudiated_claims();

            let len: u32 = pending_claims_array.len().into();

            for i in 0..len {

                let desired_claim: InsuranceClaim = pending_claims_array.at(i).clone();

                let proof_urls: Array<ByteArray> = self._get_claim_evidence_urls_for_current_claim(desired_claim.claim_id);

                

                let each_response_obj: InsuranceClaimResponse = InsuranceClaimResponse {
                    claim_id: desired_claim.claim_id,
                    policy_id: desired_claim.policy_id,
                    proposal_id: desired_claim.proposal_id,
                    claimant: desired_claim.claimant,
                    approved_settlement_amount: desired_claim.approved_settlement_amount,
                    claim_description: desired_claim.claim_description,
                    claim_amount: desired_claim.claim_amount,
                    alternative_account: desired_claim.alternative_account,
                    policy_class: convert_policy_code_to_class(desired_claim.policy_class_code),
                    claim_status: convert_claim_code_to_status(desired_claim.claim_status_code),
                    claim_type: convert_claim_code_to_type(desired_claim.claim_type_code),
                    submission_date: desired_claim.submission_date,
                    updated_at: desired_claim.updated_at,
                    is_approved: desired_claim.is_approved,
                    approved_at: desired_claim.approved_at,
                    is_repudiated: desired_claim.is_repudiated,
                    repudiated_at: desired_claim.repudiated_at,
                    risk_analytics_approved: desired_claim.risk_analytics_approved,
                    governance_approved: desired_claim.governance_approved,
                    is_escalated: desired_claim.is_escalated,
                    escalation_reason: desired_claim.escalation_reason.clone(),
                    claim_evidence_urls: proof_urls,
                    repudiation_reason: convert_repudiation_code_to_reason(desired_claim.repudiation_reason_code)
                };

                response_array.append(each_response_obj);
               
             
            };

            response_array

        }
    
        fn get_all_claims(
            self: @ContractState
        ) -> Array<InsuranceClaimResponse> {

            let mut response_array: Array<InsuranceClaimResponse> = array![];

            let len: u64 = self.claims_vec.len().into();

            for i in 0..len {

                let desired_claim: InsuranceClaim = self.claims_vec.at(i).read();

                let proof_urls: Array<ByteArray> = self._get_claim_evidence_urls_for_current_claim(desired_claim.claim_id);

                

                let each_response_obj: InsuranceClaimResponse = InsuranceClaimResponse {
                    claim_id: desired_claim.claim_id,
                    policy_id: desired_claim.policy_id,
                    proposal_id: desired_claim.proposal_id,
                    claimant: desired_claim.claimant,
                    claim_description: desired_claim.claim_description,
                    claim_amount: desired_claim.claim_amount,
                    approved_settlement_amount: desired_claim.approved_settlement_amount,
                    alternative_account: desired_claim.alternative_account,
                    policy_class: convert_policy_code_to_class(desired_claim.policy_class_code),
                    claim_status: convert_claim_code_to_status(desired_claim.claim_status_code),
                    claim_type: convert_claim_code_to_type(desired_claim.claim_type_code),
                    submission_date: desired_claim.submission_date,
                    updated_at: desired_claim.updated_at,
                    is_approved: desired_claim.is_approved,
                    approved_at: desired_claim.approved_at,
                    is_repudiated: desired_claim.is_repudiated,
                    repudiated_at: desired_claim.repudiated_at,
                    risk_analytics_approved: desired_claim.risk_analytics_approved,
                    governance_approved: desired_claim.governance_approved,
                    is_escalated: desired_claim.is_escalated,
                    escalation_reason: desired_claim.escalation_reason.clone(),
                    claim_evidence_urls: proof_urls,
                    repudiation_reason: convert_repudiation_code_to_reason(desired_claim.repudiation_reason_code)
                };

                response_array.append(each_response_obj);
               
             
            };

            response_array

        }

        fn get_escalated_claims(
            self: @ContractState
        ) -> Array<InsuranceClaimResponse> {

            let mut response_array: Array<InsuranceClaimResponse> = array![];

            let len: u64 = self.escalated_claims.len().into();

            for i in 0..len {

                let desired_claim: InsuranceClaim = self.escalated_claims.at(i).read();

                      let proof_urls: Array<ByteArray> = self._get_claim_evidence_urls_for_current_claim(desired_claim.claim_id);

                

                let each_response_obj: InsuranceClaimResponse = InsuranceClaimResponse {
                    claim_id: desired_claim.claim_id,
                    policy_id: desired_claim.policy_id,
                    proposal_id: desired_claim.proposal_id,
                    claimant: desired_claim.claimant,
                    claim_description: desired_claim.claim_description,
                    claim_amount: desired_claim.claim_amount,
                    approved_settlement_amount: desired_claim.approved_settlement_amount,
                    alternative_account: desired_claim.alternative_account,
                    policy_class: convert_policy_code_to_class(desired_claim.policy_class_code),
                    claim_status: convert_claim_code_to_status(desired_claim.claim_status_code),
                    claim_type: convert_claim_code_to_type(desired_claim.claim_type_code),
                    submission_date: desired_claim.submission_date,
                    updated_at: desired_claim.updated_at,
                    is_approved: desired_claim.is_approved,
                    approved_at: desired_claim.approved_at,
                    is_repudiated: desired_claim.is_repudiated,
                    repudiated_at: desired_claim.repudiated_at,
                    risk_analytics_approved: desired_claim.risk_analytics_approved,
                    governance_approved: desired_claim.governance_approved,
                    is_escalated: desired_claim.is_escalated,
                    escalation_reason: desired_claim.escalation_reason.clone(),
                    claim_evidence_urls: proof_urls,
                    repudiation_reason: convert_repudiation_code_to_reason(desired_claim.repudiation_reason_code)
                };

                response_array.append(each_response_obj);
               
             
            };

            response_array

        }
    
    
        fn escalate_claim(
            ref self: ContractState,
            claim_id: u256,
            is_escalated: bool,
            escalation_reason: ByteArray,
            proof_urls: Array<ByteArray>
        ) {

            let current_date: u64 = get_block_timestamp();

            let claim_to_update: InsuranceClaim = self.claims.read(claim_id);
            
            let policy_mint_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher { contract_address: self.policy_minting_address.read() };
            
            let claimant_policy: PolicyDataResponse = policy_mint_dispatcher.get_policy_data(claim_to_update.policy_id);

            let claimant_from_policy: ContractAddress = claimant_policy.policyholder;

            let claimant: ContractAddress = claim_to_update.claimant;

            assert!(claimant == claimant_from_policy, "Unauthorized: Claimant Account Address does not match with Policyholder Account Address on Policy Data");


            let proof_urls_length: u32 = proof_urls.len().into();

            for i in 0..proof_urls_length {

                let mut my_byte_array: ByteArray = proof_urls.at(i).clone();      
                self.claim_evidences.entry(claim_to_update.claim_id).push(my_byte_array);
                
            }


            let updated_claim: InsuranceClaim = InsuranceClaim {
                claim_id: claim_to_update.claim_id,
                policy_id: claim_to_update.policy_id,
                proposal_id: claimant_policy.proposal_id,
                claimant: claimant,
                claim_description: claim_to_update.claim_description,
                claim_amount: claim_to_update.claim_amount,
                approved_settlement_amount: claim_to_update.approved_settlement_amount,
                alternative_account: claim_to_update.alternative_account,
                policy_class_code: claim_to_update.policy_class_code,
                claim_status_code: claim_to_update.claim_status_code,
                claim_type_code: claim_to_update.claim_type_code,
                submission_date: claim_to_update.submission_date,
                updated_at: current_date,
                is_approved: claim_to_update.is_approved,
                approved_at: claim_to_update.approved_at,
                is_repudiated: claim_to_update.is_repudiated,
                repudiated_at: claim_to_update.repudiated_at,
                risk_analytics_approved: claim_to_update.risk_analytics_approved,
                governance_approved: claim_to_update.governance_approved,
                is_escalated: is_escalated,
                escalation_reason: escalation_reason,
                repudiation_reason_code: claim_to_update.repudiation_reason_code
            };


            self.escalated_claims.push(updated_claim.clone());

            self.claims.write(claim_to_update.claim_id, updated_claim);


        }
    
        fn settle_claim(
            ref self: ContractState,
            claim_id: u256,
        ) {

            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");


            let claim_to_settle: InsuranceClaim = self.claims.read(claim_id);

            let policy_mint_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher { contract_address: self.policy_minting_address.read() };
            
            let claimant_policy: PolicyDataResponse = policy_mint_dispatcher.get_policy_data(claim_to_settle.policy_id);

            let claimant_from_policy: ContractAddress = claimant_policy.policyholder;

            let claimant: ContractAddress = claim_to_settle.claimant;

            let is_risk_analytics_approved: bool = claim_to_settle.risk_analytics_approved;
            let is_governance_approved: bool = claim_to_settle.governance_approved;

            let approval_decision: bool = is_claim_approved_for_settlement(is_risk_analytics_approved, is_governance_approved);

            assert!(claimant == claimant_from_policy, "Unauthorized: Claimant Account Address does not match with Policyholder Account Address on Policy Data");
            
            assert!(approval_decision, "SettlementDenied: Claim is neither approved by Risk Analytics nor Governance");

            /////Todo whenever Treasury Contract is ready
        


        }
    
        fn set_treasury_address(
            ref self: ContractState,
            treasury_address: ContractAddress
        ) {

            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");

            self.treasury_address.write(treasury_address);
        }
    
        fn get_treasury_address(
            self: @ContractState,
        ) -> ContractAddress {

            let treasury_address: ContractAddress = self.treasury_address.read();

            treasury_address
        }
    
        fn set_proposal_form_address(
            ref self: ContractState,
            proposal_form_address: ContractAddress
        ) {

            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");

            self.proposal_form_address.write(proposal_form_address);
        }
    
        fn get_proposal_form_address(
            self: @ContractState,
        ) -> ContractAddress {

            let proposal_form_address: ContractAddress = self.proposal_form_address.read();

            proposal_form_address
        }
    
        fn set_policy_minting_address(
            ref self: ContractState,
            policy_minting_address: ContractAddress
        ) {

            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");

            self.policy_minting_address.write(policy_minting_address);
        }
    
        fn get_policy_minting_address(
            self: @ContractState,
        ) -> ContractAddress {

            let policy_minting_address: ContractAddress = self.policy_minting_address.read();

            policy_minting_address

        }
    
        fn set_governance_address(
            ref self: ContractState,
            governance_address: ContractAddress
        ) {
            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");

            self.governance_address.write(governance_address);
        }
    
        fn get_governance_address(
            self: @ContractState,
        ) -> ContractAddress {

            let governance_address: ContractAddress = self.governance_address.read();

            governance_address
        }
    
        fn set_auto_approval_limit(
            ref self: ContractState,
            auto_approval_limit: u256
        ) {
            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");

            self.auto_approval_limit.write(auto_approval_limit);
        }
    
        fn get_auto_approval_limit(
            self: @ContractState,
        ) -> u256 {

            let auto_approval_limit: u256 = self.auto_approval_limit.read();

            auto_approval_limit
        }
    
        fn set_max_claim_amount_payable(
            ref self: ContractState,
            max_claim_amount_payable: u256
        ) {
            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");

            self.max_claim_amount_payable.write(max_claim_amount_payable);
        }
    
        fn get_max_claim_amount_payable(
            self: @ContractState,
        ) -> u256 {

            let max_claim_amount_payable: u256 = self.max_claim_amount_payable.read();

            max_claim_amount_payable

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

        #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _get_claim_evidence_urls_for_current_claim(
            self: @ContractState,
            claim_id: u256
        ) -> Array<ByteArray> {


            let sought_claim: InsuranceClaim = self.claims.read(claim_id);
            
            let mut proof_urls: Array<ByteArray> = array![];

            let len: u64 = self.claim_evidences.entry(sought_claim.claim_id).len();

            for i in 0..len {
                let mut each_url: ByteArray = self.claim_evidences.entry(sought_claim.claim_id).at(i).read();
                proof_urls.append(each_url);
            }

            proof_urls
        }


        fn _filter_out_settled_and_repudiated_claims(
            self: @ContractState
        ) -> Array<InsuranceClaim> {
            let mut filtered_claims_array: Array<InsuranceClaim> = array![];

            let len: u64 = self.claims_vec.len();

            for i in 0..len {

                let current_status_code: u8 = self.claims_vec.at(i).read().claim_status_code.into();


                if current_status_code == convert_claim_status_to_code(ClaimStatus::Repudiated) {
                    continue;
                } else if current_status_code == convert_claim_status_to_code(ClaimStatus::Settled) {
                    continue;
                } else {
                    filtered_claims_array.append(self.claims_vec.at(i).read());
                }
            }

            filtered_claims_array
        }

    }

}