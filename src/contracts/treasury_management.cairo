#[starknet::contract]
pub mod TreasuryManagement {
use starknet::{ ContractAddress, ClassHash };
    use starknet::{
        get_caller_address,
        // get_contract_address,
        get_block_timestamp,
        get_tx_info,
        TxInfo
    };
    // use core::integer::zeroable::Zeroable;
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::interface::{ 
        IERC20Dispatcher,
        IERC20DispatcherTrait
    };
    // use openzeppelin::token::erc721::interface::IERC721Dispatcher;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;



    use starknet::storage::{
        Map,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess
    };

    use crate::structs::structs::*;
    use crate::enums::enums::*;
    use crate::event_structs::event_structs::*;
    use crate::utils::utils::*;
    use crate::interfaces::interfaces::*;



      // Roles
      const TREASURY_MANAGER_ROLE: felt252 = selector!("TREASURY_MANAGER_ROLE");
      const TREASURY_GUARDIAN_ROLE: felt252 = selector!("TREASURY_GUARDIAN_ROLE");
      const DEFAULT_ADMIN_ROLE: felt252 = selector!("DEFAULT_ADMIN_ROLE");
      const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");

  
      // Withdrawal proposal status
      const STATUS_PENDING: felt252 = selector!("STATUS_PENDING");
      const STATUS_APPROVED: felt252 = selector!("STATUS_APPROVED");
      const STATUS_EXECUTED: felt252 = selector!("STATUS_EXECUTED");
      const STATUS_REJECTED: felt252 = selector!("STATUS_REJECTED");



    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);




    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

   
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;




    #[storage]
    pub struct Storage {
        // OpenZeppelin Components
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        reentrancyguard: ReentrancyGuardComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,


        next_transaction_id: u256,
        next_reinsurer_id: u256,

        reinsurers: Map<u256, Reinsurer>,

        //premium payment data by transaction_id
        premiums: Map<u256, PremiumPayment>,
        //By transaction_id
        claim_payments: Map<u256, ClaimPayment>,
        //By transaction_id --- Debits Starknet-Indemnify STINDEM Balance
        native_token_purchases: Map<u256, NativeTokenPurchase>,
        //By transaction_id --- Credits Starknet-Indeminfy STINDEM Balance
        native_token_recoveries: Map<u256, NativeTokenRecovery>,
        //By transaction_id --- Credits Starknet-Indemnify STINDEM Balance
        vote_right_payments: Map<u256, PurchaseVotingCommitment>,
        //Set Reinsurances by Transaction IDs
        reinsurance_setting_txns: Map<u256, CreditReinsurance>, 
        //Recover Reinsurance to settle reinsured risks claims
        reinsurance_recovery_txns: Map<u256, DebitReinsurance>,                                                                                                                                                                                                                                               
        //Current balance of Investors' fund
        investors_fund_balance: u256,
        gross_premium_written: u256,
        claims_reserve: u256,
        total_premium_allocated_to_reinsurance: u256,
        total_premium_allocated_to_investors_pool: u256,
        total_claims_value_drawn_from_investors_pool: u256,
        total_claims_value_drawn_from_reinsurance: u256,
        total_value_of_claims_paid: u256,
        total_value_of_incurred_claims: u256,
        total_value_of_repudiated_claims: u256,
    
        //STINDEM token address
        stindem_token_address: ContractAddress, 


        //Conversion rates
        current_stindem_to_strk_value: u256,
        current_stindem_to_eth_value: u256,
        current_stindem_to_btc_value: u256,
        current_stindem_to_usd_value: u256,  
        current_strk_to_usd_value: u256,
        current_strk_to_eth_value: u256,
        current_strk_to_btc_value: u256,

        //Currencies balances
        starknet_indemnify_usd_balance: u256,
        starknet_indemnify_strk_balance: u256,
        starknet_indemnify_stindem_balance: u256,
        starknet_indemnify_eth_balance: u256,
        starknet_indemnify_btc_balance: u256,


        stindem_qty_to_vote: u256,

        proposal_form_address: ContractAddress,
        policy_minting_address: ContractAddress,
        claims_contract_address: ContractAddress,
        governance_contract_address: ContractAddress,
        strk_contract_address: ContractAddress,
        starknet_indemnify_treasury_account: ContractAddress,
        starknet_indemnify_stindem_treasury: ContractAddress,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,

        PremiumPaymentSuccess: PremiumPaymentSuccess,
    
        // Add the new premium payment events
        PremiumPaymentRecorded: PremiumPaymentRecorded,
        PremiumPaymentUpdated: PremiumPaymentUpdated,
        
          // Add the new claim payment events
        ClaimPaymentExecuted: ClaimPaymentExecuted,
        ClaimPaymentUpdated: ClaimPaymentUpdated,
        
        // Your existing claim events
        ClaimSubmitted: ClaimSubmitted,
        ClaimUpdated: ClaimUpdated,
        ClaimApproved: ClaimApproved,
        ClaimRepudiated: ClaimRepudiated,
        ClaimPaid: ClaimPaid,
        ClaimEscalated: ClaimEscalated,
        
        ///Stindem purchase events
        StindemPurchased: StindemPurchased,
        StindemPurchaseUpdated: StindemPurchaseUpdated,

        ///Stindem recovery event
        StindemRecovered: StindemRecovered,
        StindemRecoveryUpdated: StindemRecoveryUpdated,
        
           // Add the new voting commitment events
        VotingCommitmentPurchased: VotingCommitmentPurchased,
        VotingCommitmentUpdated: VotingCommitmentUpdated,
    
    }
    

  

   

   
  
    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
    ) {
        // Initialize OpenZeppelin components
        self.accesscontrol.initializer();
        // Setup roles
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, admin);
        self.accesscontrol._grant_role(ADMIN_ROLE, admin);

    

        self.next_transaction_id.write(1);
        self.next_reinsurer_id.write(1);

        // Set timelock duration
    }

    
        #[abi(embed_v0)]
    pub impl TreasuryManagementImpl of ITreasuryManagement<ContractState> {

        fn pay_premium(
            ref self: ContractState,
            proposal_id: u256,
            payer_address: ContractAddress,
        ) -> u256 {

            let current_txn_id: u256 = self.next_transaction_id.read();

            let proposal_form_dispatcher: IProposalFormDispatcher = IProposalFormDispatcher {
                contract_address: self.proposal_form_address.read()
            };

            let proposal_obj: ProposalFormResponse = proposal_form_dispatcher.get_proposal_by_id(proposal_id);

            let is_risk_analytics_approved: bool = proposal_obj.risk_analytics_approved;
            let is_governance_approved: bool = proposal_obj.governance_approved;

            let is_premium_payment_allowed: bool = is_proposal_approved_for_premium_payment(
                is_risk_analytics_approved, 
                is_governance_approved
            );

            assert!(is_premium_payment_allowed, "Unathorized: Proposal form has not been approved for premium payment");           

            let actual_premium_payable: u256 = proposal_obj.premium_payable;

            let treasury_account: ContractAddress = self.starknet_indemnify_treasury_account.read();

            let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher {
                contract_address: self.strk_contract_address.read()
            }; 

            let caller: ContractAddress = get_caller_address();

            let balance: u256 = strk_dispatcher.balance_of(caller);

            assert!(balance >= actual_premium_payable, "Caller doesn't have enough balance");

            // let contract: ContractAddress = get_contract_address();

            let allowance: u256 = strk_dispatcher.allowance(caller, treasury_account);

            assert!(allowance >= actual_premium_payable, "Treasury Account is not allowed to spend enough premium");


            let success: bool = strk_dispatcher.transfer_from(caller, treasury_account, actual_premium_payable);

            assert!(success, "Premium payment failed");


            let policy_minting_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher {
                contract_address: self.policy_minting_address.read()
            };

            let new_policy_id: u256 = policy_minting_dispatcher.mint_policy(proposal_id); 

            let current_time: u64 = get_block_timestamp();   

            let txn_info: TxInfo = get_tx_info().unbox();

            let txn_hash: felt252 = txn_info.transaction_hash;



            let new_payment: PremiumPayment = PremiumPayment {
                transaction_id: current_txn_id,
                proposal_id: proposal_id,
                policy_id: new_policy_id,
                payer_address: payer_address,
                policyholder: proposal_obj.proposer,
                amount_paid: actual_premium_payable,
                sum_insured: proposal_obj.sum_insured,
                payment_date: current_time,
                updated_at: current_time,
                txn_hash: txn_hash,
                payment_status_code:  convert_payment_status_to_code(PaymentStatus::Successful)
            };

            self.premiums.write(current_txn_id, new_payment);

            let incremented_txn_id: u256 = current_txn_id + 1;

            self.next_transaction_id.write(incremented_txn_id);


             // Emit PremiumPaymentRecorded event
            let premium_payment_event: PremiumPaymentRecorded = PremiumPaymentRecorded {
                transaction_id: current_txn_id,
                proposal_id: proposal_id,
                policy_id: new_policy_id,
                payer_address: payer_address,
                policyholder: proposal_obj.proposer,
                amount_paid: actual_premium_payable,
                sum_insured: proposal_obj.sum_insured,
                payment_date: current_time,
                txn_hash: txn_hash
            };
            self.emit(premium_payment_event);

            // Also emit the existing PremiumPaymentSuccess event for backward compatibility
            let payment_success_event: PremiumPaymentSuccess = PremiumPaymentSuccess {
                proposal_id: proposal_id,
                policyholder: proposal_obj.proposer,
                payer: payer_address,
                amount: actual_premium_payable,
                policy_token_id: new_policy_id, // Assuming this is the same as policy_id
                policy_id: new_policy_id
            };
            self.emit(payment_success_event);


             current_txn_id
        }
    
        fn update_premium_payment(
            ref self: ContractState,
            transaction_id: u256,
            policy_id: u256,
            txn_hash: felt252,
            payment_status_code: u8 
        ) {

            let updateable_premium_payment: PremiumPayment = self.premiums.read(transaction_id);

            let current_time: u64 = get_block_timestamp();

            let updated_premium_payment: PremiumPayment = PremiumPayment {
                transaction_id: transaction_id,
                proposal_id: updateable_premium_payment.proposal_id,
                policy_id: policy_id,
                payer_address: updateable_premium_payment.payer_address,
                policyholder: updateable_premium_payment.policyholder,
                amount_paid: updateable_premium_payment.amount_paid,
                sum_insured: updateable_premium_payment.sum_insured,
                payment_date: updateable_premium_payment.payment_date,
                updated_at: current_time,
                txn_hash: txn_hash,
                payment_status_code:  payment_status_code
            };

            self.premiums.write(transaction_id, updated_premium_payment);

             // Emit PremiumPaymentUpdated event
            let premium_update_event: PremiumPaymentUpdated = PremiumPaymentUpdated {
                transaction_id: transaction_id,
                policy_id: policy_id,
                txn_hash: txn_hash,
                payment_status: convert_payment_code_to_status(payment_status_code),
                updated_at: current_time
            };
            self.emit(premium_update_event);

        }
    
        fn get_premium_payment(
            self: @ContractState,
            transaction_id: u256
        ) -> PremiumPaymentResponse {

            let sought_premium_payment: PremiumPayment = self.premiums.read(transaction_id);

            let response_obj: PremiumPaymentResponse = PremiumPaymentResponse {
                    transaction_id: transaction_id,
                    proposal_id: sought_premium_payment.proposal_id,
                    policy_id: sought_premium_payment.policy_id,
                    payer_address: sought_premium_payment.payer_address,
                    policyholder: sought_premium_payment.policyholder,
                    amount_paid: sought_premium_payment.amount_paid,
                    sum_insured: sought_premium_payment.sum_insured,
                    payment_date: sought_premium_payment.payment_date,
                    updated_at: sought_premium_payment.updated_at,
                    txn_hash: sought_premium_payment.txn_hash,
                    payment_status: convert_payment_code_to_status(sought_premium_payment.payment_status_code)
            };

            response_obj
        }
    
        fn pay_claim(
            ref self: ContractState,
            policy_id: u256,
            claim_id: u256,
            policyholder: ContractAddress,
            third_party_account: ContractAddress,
            settlement_source_code: u8
        ) -> u256 {

            let current_txn_id: u256 = self.next_transaction_id.read();

            let current_time: u64 = get_block_timestamp();


            let policy_minting_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher {
                contract_address: self.policy_minting_address.read()
            };

            let claim_dispatcher: IClaimDispatcher = IClaimDispatcher {
                contract_address: self.claims_contract_address.read()
            };

            let policy_obj: PolicyDataResponse = policy_minting_dispatcher.get_policy_data(policy_id);
            let claim_obj: InsuranceClaimResponse = claim_dispatcher.get_claim_by_id(claim_id);

            let is_governance_approved: bool = claim_obj.governance_approved;
            let is_risk_analytics_approved: bool = claim_obj.risk_analytics_approved;

            let claim_is_approved: bool = is_claim_approved_for_settlement(
                is_risk_analytics_approved,
                is_governance_approved
            );

            let payable_claim_amount: u256 = claim_obj.approved_settlement_amount;

            assert!(claim_is_approved, "PaymentDenied: Claim has not been approved for settlement");

            let treasury_account: ContractAddress = self.starknet_indemnify_treasury_account.read();


            let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher {
                contract_address: self.strk_contract_address.read()
            }; 

            // let caller: ContractAddress = get_caller_address();

            let balance: u256 = strk_dispatcher.balance_of(treasury_account);

            assert!(balance >= payable_claim_amount, "Treasury Account doesn't have enough balance");

            let allowance: u256 = strk_dispatcher.allowance(treasury_account, policyholder);

            assert!(allowance >= payable_claim_amount, "Policyholder is not allowed to spend enough claimed token");


            let success: bool = strk_dispatcher.transfer_from(treasury_account, policyholder, payable_claim_amount);

            assert!(success, "Claim payment failed");




            let txn_info: TxInfo = get_tx_info().unbox();

            let txn_hash: felt252 = txn_info.transaction_hash;


            let paid_claim_txn: ClaimPayment = ClaimPayment {
                transaction_id: current_txn_id,
                proposal_id: policy_obj.proposal_id,
                policy_id: policy_id,
                claim_id: claim_id,
                policyholder: policyholder,
                third_party_account: third_party_account,
                claim_amount: claim_obj.claim_amount,
                approved_settlement_amount: claim_obj.approved_settlement_amount,
                settlement_date: current_time,
                updated_at: current_time,
                txn_hash: txn_hash,
                settlement_status_code: convert_payment_status_to_code(PaymentStatus::Successful),
                settlement_source_code: settlement_source_code
            };

            self.claim_payments.write(current_txn_id, paid_claim_txn);

            let incremented_txn_id: u256 = current_txn_id + 1;

            self.next_transaction_id.write(incremented_txn_id);


             // Emit ClaimPaymentExecuted event
            let claim_payment_event: ClaimPaymentExecuted = ClaimPaymentExecuted {
                transaction_id: current_txn_id,
                policy_id: policy_id,
                claim_id: claim_id,
                policyholder: policyholder,
                third_party_account: third_party_account,
                claim_amount: claim_obj.claim_amount,
                approved_settlement_amount: claim_obj.approved_settlement_amount,
                settlement_date: current_time,
                txn_hash: txn_hash,
                settlement_source: convert_claims_settlement_source_code_to_source(settlement_source_code)
            };
            self.emit(claim_payment_event);

            // Also emit the existing ClaimPaid event for backward compatibility
            let claim_paid_event: ClaimPaid = ClaimPaid {
                claim_id: claim_id,
                recipient: policyholder,
                amount: payable_claim_amount,
                tx_hash: txn_hash
            };
            self.emit(claim_paid_event);

            current_txn_id
        }
    
        fn update_claim_payment(
            ref self: ContractState,
            transaction_id: u256,
            third_party_account: ContractAddress,
            txn_hash: felt252,
            settlement_status_code: u8,
            settlement_source_code: u8
        ) {

            let claim_to_update: ClaimPayment = self.claim_payments.read(transaction_id);

            let current_time: u64 = get_block_timestamp();

            let updated_claim: ClaimPayment = ClaimPayment {
                transaction_id: transaction_id,
                proposal_id: claim_to_update.proposal_id,
                policy_id: claim_to_update.policy_id,
                claim_id: claim_to_update.claim_id,
                policyholder: claim_to_update.policyholder,
                third_party_account: third_party_account,
                claim_amount: claim_to_update.claim_amount,
                approved_settlement_amount: claim_to_update.approved_settlement_amount,
                settlement_date: claim_to_update.settlement_date,
                updated_at: current_time,
                txn_hash: txn_hash,
                settlement_status_code: settlement_status_code,
                settlement_source_code: settlement_source_code
            };

            self.claim_payments.write(transaction_id, updated_claim);

            // Emit ClaimPaymentUpdated event
            let claim_update_event: ClaimPaymentUpdated = ClaimPaymentUpdated {
                transaction_id: transaction_id,
                policy_id: claim_to_update.policy_id,
                claim_id: claim_to_update.claim_id,
                policyholder: claim_to_update.policyholder,
                third_party_account: third_party_account,
                settlement_status: convert_payment_code_to_status(settlement_status_code),
                settlement_source: convert_claims_settlement_source_code_to_source(settlement_source_code),
                updated_at: current_time,
                txn_hash: txn_hash
            };
            self.emit(claim_update_event);
        }
    
        fn get_claim_payment(
            self: @ContractState,
            transaction_id: u256
        ) -> ClaimPaymentResponse {

            let sought_claim_payment: ClaimPayment = self.claim_payments.read(transaction_id);

            let response_obj: ClaimPaymentResponse = ClaimPaymentResponse {
                transaction_id: transaction_id,
                proposal_id: sought_claim_payment.proposal_id,
                policy_id: sought_claim_payment.policy_id,
                claim_id: sought_claim_payment.claim_id,
                policyholder: sought_claim_payment.policyholder,
                third_party_account: sought_claim_payment.third_party_account,
                claim_amount: sought_claim_payment.claim_amount,
                approved_settlement_amount: sought_claim_payment.approved_settlement_amount,
                settlement_date: sought_claim_payment.settlement_date,
                updated_at: sought_claim_payment.updated_at,
                txn_hash: sought_claim_payment.txn_hash,
                settlement_status: convert_payment_code_to_status(sought_claim_payment.settlement_status_code),
                settlement_source: convert_claims_settlement_source_code_to_source(sought_claim_payment.settlement_source_code)
            };


            response_obj

        }
    
        fn purchase_stindem(
            ref self: ContractState,
            buyer_address: ContractAddress,
            quantity: u256,
        ) -> u256 {

            let current_txn_id: u256 = self.next_transaction_id.read();


            let treasury_account: ContractAddress = self.starknet_indemnify_treasury_account.read();

            let stindem_treasury: ContractAddress = self.starknet_indemnify_stindem_treasury.read();

            let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher {
                contract_address: self.strk_contract_address.read()
            }; 

            let stindem_dispatcher: IERC20Dispatcher = IERC20Dispatcher {
                contract_address: self.stindem_token_address.read()
            };

            let unit_price_of_stindem_in_strk: u256 = 1/self.current_stindem_to_strk_value.read();

            let amount_of_strk_to_bill: u256 = unit_price_of_stindem_in_strk * quantity;

            let caller: ContractAddress = get_caller_address();

            let balance: u256 = strk_dispatcher.balance_of(caller);

            let stindem_balance: u256 = stindem_dispatcher.balance_of(stindem_treasury);

            assert!(stindem_balance >= quantity, "STINDEM Treasury balance is low");

            assert!(balance >= amount_of_strk_to_bill, "Caller doesn't have enough STRK balance");

            let allowance: u256 = strk_dispatcher.allowance(caller, treasury_account);

            let stindem_allowance: u256 = stindem_dispatcher.allowance(stindem_treasury, buyer_address);

            assert!(stindem_allowance >= quantity, "Buyer is not allowed to spend enough STINDEM");

            assert!(allowance >= amount_of_strk_to_bill, "Treasury Account is not allowed to spend enough STRK");


            let success: bool = strk_dispatcher.transfer_from(caller, treasury_account, amount_of_strk_to_bill);

            assert!(success, "Billing STRK failed");

            let successfulTransfer: bool = stindem_dispatcher.transfer_from(stindem_treasury, buyer_address, quantity);

            assert!(successfulTransfer, "Transferring STINDEM failed");

            let current_time: u64 = get_block_timestamp();

            let txn_info: TxInfo = get_tx_info().unbox();

            let txn_hash: felt252 = txn_info.transaction_hash;

            let native_token_sale: NativeTokenPurchase = NativeTokenPurchase {
                transaction_id: current_txn_id,
                buyer_address: buyer_address,
                seller_address: stindem_treasury,
                token_address: self.stindem_token_address.read(),
                token_symbol: "STINDEM",
                quantity: quantity,
                unit_price: unit_price_of_stindem_in_strk,
                total_price_paid: amount_of_strk_to_bill,
                payment_date: current_time,
                updated_at: current_time,
                txn_hash: txn_hash,
                payment_status_code: convert_payment_status_to_code(PaymentStatus::Successful)
            };

            self.native_token_purchases.write(current_txn_id, native_token_sale);    


            let incremented_txn_id: u256 = current_txn_id + 1;

            self.next_transaction_id.write(incremented_txn_id);

               // Emit StindemPurchased event
            let stindem_purchase_event: StindemPurchased = StindemPurchased {
                transaction_id: current_txn_id,
                buyer_address: buyer_address,
                seller_address: stindem_treasury,
                token_address: self.stindem_token_address.read(),
                quantity: quantity,
                unit_price: unit_price_of_stindem_in_strk,
                total_price_paid: amount_of_strk_to_bill,
                payment_date: current_time,
                txn_hash: txn_hash
            };
            self.emit(stindem_purchase_event);

            current_txn_id

        }
    
        fn update_stindem_purchase_detail(
            ref self: ContractState,
            transaction_id: u256,
            txn_hash: felt252,
            payment_status_code: u8
        ) {
            let updateable_txn: NativeTokenPurchase = self.native_token_purchases.read(transaction_id);

            let current_time: u64 = get_block_timestamp();

            let updated_txn: NativeTokenPurchase = NativeTokenPurchase {
                transaction_id: transaction_id,
                buyer_address: updateable_txn.buyer_address,
                seller_address: updateable_txn.seller_address,
                token_address: updateable_txn.token_address,
                token_symbol: updateable_txn.token_symbol,
                quantity: updateable_txn.quantity,
                unit_price: updateable_txn.unit_price,
                total_price_paid: updateable_txn.total_price_paid,
                payment_date: updateable_txn.payment_date,
                updated_at: current_time,
                txn_hash: txn_hash,
                payment_status_code: payment_status_code
            };

            self.native_token_purchases.write(transaction_id, updated_txn);

              // Emit StindemPurchaseUpdated event
            let stindem_update_event: StindemPurchaseUpdated = StindemPurchaseUpdated {
                transaction_id: transaction_id,
                buyer_address: updateable_txn.buyer_address,
                token_address: updateable_txn.token_address,
                quantity: updateable_txn.quantity,
                payment_status: convert_payment_code_to_status(payment_status_code),
                updated_at: current_time,
                txn_hash: txn_hash
            };
            self.emit(stindem_update_event);
        }
    
        fn get_stindem_purchase_detail(
            self: @ContractState,
            transaction_id: u256
        ) -> NativeTokenPurchaseResponse {

            let sought_txn: NativeTokenPurchase = self.native_token_purchases.read(transaction_id);

            let response_obj: NativeTokenPurchaseResponse = NativeTokenPurchaseResponse {
                transaction_id: transaction_id,
                buyer_address: sought_txn.buyer_address,
                seller_address: sought_txn.seller_address,
                token_address: sought_txn.token_address,
                token_symbol: sought_txn.token_symbol,
                quantity: sought_txn.quantity,
                unit_price: sought_txn.unit_price,
                total_price_paid: sought_txn.total_price_paid,
                payment_date: sought_txn.payment_date,
                updated_at: sought_txn.updated_at,
                txn_hash: sought_txn.txn_hash,
                payment_status: convert_payment_code_to_status(sought_txn.payment_status_code)
            };

            response_obj
        }
    
        fn recover_stindem_from_market(
            ref self: ContractState,
            seller_address: ContractAddress,
            quantity: u256,
        ) -> u256 {

            let current_txn_id: u256 = self.next_transaction_id.read();


            let treasury_account: ContractAddress = self.starknet_indemnify_treasury_account.read();

            let stindem_treasury: ContractAddress = self.starknet_indemnify_stindem_treasury.read();

            let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher {
                contract_address: self.strk_contract_address.read()
            }; 

            let stindem_dispatcher: IERC20Dispatcher = IERC20Dispatcher {
                contract_address: self.stindem_token_address.read()
            };

            let unit_price_of_stindem_in_strk: u256 = 1/self.current_stindem_to_strk_value.read();

            let amount_of_strk_to_bill: u256 = unit_price_of_stindem_in_strk * quantity;

            let caller: ContractAddress = get_caller_address();

            let balance: u256 = strk_dispatcher.balance_of(treasury_account);

            let stindem_balance: u256 = stindem_dispatcher.balance_of(caller);

            assert!(stindem_balance >= quantity, "Caller STINDEM balance is low");

            assert!(balance >= amount_of_strk_to_bill, "Treasury doesn't have enough STRK balance");

            let allowance: u256 = strk_dispatcher.allowance(treasury_account, seller_address);

            let stindem_allowance: u256 = stindem_dispatcher.allowance(caller, stindem_treasury);

            assert!(stindem_allowance >= quantity, "STINDEM TREASURY is not allowed to spend enough STINDEM");

            assert!(allowance >= amount_of_strk_to_bill, "Seller is not allowed to spend enough STRK");


            let success: bool = strk_dispatcher.transfer_from(treasury_account, seller_address, amount_of_strk_to_bill);

            assert!(success, "Transferring STRK failed");

            let successfulTransfer: bool = stindem_dispatcher.transfer_from(caller, stindem_treasury, quantity);

            assert!(successfulTransfer, "Transferring STINDEM failed");

            let current_time: u64 = get_block_timestamp();

            let txn_info: TxInfo = get_tx_info().unbox();

            let txn_hash: felt252 = txn_info.transaction_hash;

            let native_token_recovered: NativeTokenRecovery = NativeTokenRecovery {
                transaction_id: current_txn_id,
                seller_address: seller_address,
                buyer_address: treasury_account,
                token_address: self.strk_contract_address.read(),
                token_symbol: "STRK",
                quantity: quantity,
                unit_price: unit_price_of_stindem_in_strk,
                total_price_paid: amount_of_strk_to_bill,
                payment_date: current_time,
                updated_at: current_time,
                txn_hash: txn_hash,
                payment_status_code: convert_payment_status_to_code(PaymentStatus::Successful)
            };

            self.native_token_recoveries.write(current_txn_id, native_token_recovered);    


            let incremented_txn_id: u256 = current_txn_id + 1;

            self.next_transaction_id.write(incremented_txn_id);

               // Emit StindemRecovered event
            let stindem_recovery_event: StindemRecovered = StindemRecovered {
                transaction_id: current_txn_id,
                seller_address: seller_address,
                buyer_address: treasury_account,
                stindem_token_address: self.stindem_token_address.read(),
                strk_token_address: self.strk_contract_address.read(),
                stindem_quantity: quantity,
                strk_amount_paid: amount_of_strk_to_bill,
                unit_price: unit_price_of_stindem_in_strk,
                recovery_date: current_time,
                txn_hash: txn_hash
            };
            self.emit(stindem_recovery_event);

            current_txn_id

        }
    
        fn update_stindem_recovery_from_market(
            ref self: ContractState,
            transaction_id: u256,
            txn_hash: felt252,
            payment_status_code: u8
        ) {

            let updateable_txn: NativeTokenRecovery = self.native_token_recoveries.read(transaction_id);

            let current_time: u64 = get_block_timestamp();

            let updated_txn: NativeTokenRecovery = NativeTokenRecovery {
                transaction_id: transaction_id,
                seller_address: updateable_txn.seller_address,
                buyer_address: updateable_txn.buyer_address,
                token_address: updateable_txn.token_address,
                token_symbol: updateable_txn.token_symbol,
                quantity: updateable_txn.quantity,
                unit_price: updateable_txn.unit_price,
                total_price_paid: updateable_txn.total_price_paid,
                payment_date: updateable_txn.payment_date,
                updated_at: current_time,
                txn_hash: txn_hash,
                payment_status_code: payment_status_code
            };

            self.native_token_recoveries.write(transaction_id, updated_txn);

             // Emit StindemRecoveryUpdated event
            let stindem_recovery_update_event: StindemRecoveryUpdated = StindemRecoveryUpdated {
                transaction_id: transaction_id,
                seller_address: updateable_txn.seller_address,
                stindem_quantity: updateable_txn.quantity,
                strk_amount_paid: updateable_txn.total_price_paid,
                payment_status: convert_payment_code_to_status(payment_status_code),
                updated_at: current_time,
                txn_hash: txn_hash
            };
            self.emit(stindem_recovery_update_event);
        }
    
        fn get_stindem_recovery_txn_detail(
            self: @ContractState,
            transaction_id: u256
        ) -> NativeTokenRecoveryResponse {

            let sought_txn: NativeTokenRecovery = self.native_token_recoveries.read(transaction_id);

            let response_obj: NativeTokenRecoveryResponse = NativeTokenRecoveryResponse {
                transaction_id: transaction_id,
                seller_address: sought_txn.seller_address,
                buyer_address: sought_txn.buyer_address,
                token_address: sought_txn.token_address,
                token_symbol: sought_txn.token_symbol,
                quantity: sought_txn.quantity,
                unit_price: sought_txn.unit_price,
                total_price_paid: sought_txn.total_price_paid,
                payment_date: sought_txn.payment_date,
                updated_at: sought_txn.updated_at,
                txn_hash: sought_txn.txn_hash,
                payment_status: convert_payment_code_to_status(sought_txn.payment_status_code)
            };

            response_obj

        }
    
        fn purchase_voting_commitment(
            ref self: ContractState,
            seller_address: ContractAddress,
        ) -> (u256, felt252) {

            let current_txn_id: u256 = self.next_transaction_id.read();

            let quantity: u256 = self.stindem_qty_to_vote.read();



            let stindem_treasury: ContractAddress = self.starknet_indemnify_stindem_treasury.read();

          

            let stindem_dispatcher: IERC20Dispatcher = IERC20Dispatcher {
                contract_address: self.stindem_token_address.read()
            };

            let unit_price_of_stindem_in_strk: u256 = 1/self.current_stindem_to_strk_value.read();

            let caller: ContractAddress = get_caller_address();


            let stindem_balance: u256 = stindem_dispatcher.balance_of(caller);

            assert!(stindem_balance >= quantity, "Caller STINDEM balance is low");

            let stindem_allowance: u256 = stindem_dispatcher.allowance(caller, stindem_treasury);

            assert!(stindem_allowance >= quantity, "STINDEM TREASURY is not allowed to spend enough STINDEM");


            let successfulTransfer: bool = stindem_dispatcher.transfer_from(caller, stindem_treasury, quantity);

            assert!(successfulTransfer, "Transferring STINDEM failed");

            let current_time: u64 = get_block_timestamp();

            let txn_info: TxInfo = get_tx_info().unbox();

            let txn_hash: felt252 = txn_info.transaction_hash;

            let vote_right_purchase: PurchaseVotingCommitment = PurchaseVotingCommitment {
                transaction_id: current_txn_id,
                seller_address: seller_address,
                buyer_address: stindem_treasury,
                token_address: self.stindem_token_address.read(),
                token_symbol: "STINDEM",
                quantity: quantity,
                unit_price: unit_price_of_stindem_in_strk,
                total_price_paid: 0,
                payment_date: current_time,
                updated_at: current_time,
                txn_hash: txn_hash,
                payment_status_code: convert_payment_status_to_code(PaymentStatus::Successful)
            };


            self.vote_right_payments.write(current_txn_id, vote_right_purchase);    


            let incremented_txn_id: u256 = current_txn_id + 1;

            self.next_transaction_id.write(incremented_txn_id);

              // Emit VotingCommitmentPurchased event
            let voting_commitment_event: VotingCommitmentPurchased = VotingCommitmentPurchased {
                transaction_id: current_txn_id,
                voter_address: caller, // The actual voter/caller
                treasury_address: stindem_treasury,
                stindem_token_address: self.stindem_token_address.read(),
                stindem_quantity: quantity,
                unit_price: unit_price_of_stindem_in_strk,
                commitment_date: current_time,
                txn_hash: txn_hash
            };
            self.emit(voting_commitment_event);

            (current_txn_id, txn_hash)

        }
    
        fn update_voting_commitment_purchase(
            ref self: ContractState,
            transaction_id: u256,
            txn_hash: felt252,
            payment_status_code: u8
        ) {

            let updateable_txn: PurchaseVotingCommitment = self.vote_right_payments.read(transaction_id);

            let current_time: u64 = get_block_timestamp();

            let updated_txn: PurchaseVotingCommitment = PurchaseVotingCommitment {
                transaction_id: transaction_id,
                seller_address: updateable_txn.seller_address,
                buyer_address: updateable_txn.buyer_address,
                token_address: updateable_txn.token_address,
                token_symbol: updateable_txn.token_symbol,
                quantity: updateable_txn.quantity,
                unit_price: updateable_txn.unit_price,
                total_price_paid: updateable_txn.total_price_paid,
                payment_date: updateable_txn.payment_date,
                updated_at: current_time,
                txn_hash: txn_hash,
                payment_status_code: payment_status_code
            };

            self.vote_right_payments.write(transaction_id, updated_txn);

             // Emit VotingCommitmentUpdated event
            let voting_commitment_update_event: VotingCommitmentUpdated = VotingCommitmentUpdated {
                transaction_id: transaction_id,
                voter_address: updateable_txn.seller_address, // seller_address is the voter in this context
                stindem_quantity: updateable_txn.quantity,
                payment_status: convert_payment_code_to_status(payment_status_code),
                updated_at: current_time,
                txn_hash: txn_hash
            };
            self.emit(voting_commitment_update_event);

        }
    
        fn get_voting_commitment_purchase_detail(
            self: @ContractState,
            transaction_id: u256
        ) -> PurchaseVotingCommitmentResponse {

            let sought_txn: PurchaseVotingCommitment = self.vote_right_payments.read(transaction_id);

            let response_obj: PurchaseVotingCommitmentResponse = PurchaseVotingCommitmentResponse {
                transaction_id: transaction_id,
                seller_address: sought_txn.seller_address,
                buyer_address: sought_txn.buyer_address,
                token_address: sought_txn.token_address,
                token_symbol: sought_txn.token_symbol,
                quantity: sought_txn.quantity,
                unit_price: sought_txn.unit_price,
                total_price_paid: sought_txn.total_price_paid,
                payment_date: sought_txn.payment_date,
                updated_at: sought_txn.updated_at,
                txn_hash: sought_txn.txn_hash,
                payment_status: convert_payment_code_to_status(sought_txn.payment_status_code)
            };

            response_obj
        }
    
        fn initiate_reinsurance_premium_payment(
            ref self: ContractState,
            insured_proposal_id: u256,
            insured_policy_id: u256,
            reinsurer_id: u256,
            reinsurance_payment_address: ContractAddress,
            percentage_reinsurance: u16,
            gross_sum_insured: u256,
            ceded_sum_insured: u256,
            gross_premium: u256,
            ceded_premium: u256,
        ) -> u256 {

            let current_txn_id: u256 = self.next_transaction_id.read();

            let policy_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher {
                contract_address: self.policy_minting_address.read()
            };

            let proposal_dispatcher: IProposalFormDispatcher = IProposalFormDispatcher {
                contract_address: self.proposal_form_address.read()
            };

            let proposal_obj: ProposalFormResponse = proposal_dispatcher.get_proposal_by_id(insured_proposal_id);

            let policy_obj: PolicyDataResponse = policy_dispatcher.get_policy_data(insured_policy_id);

            proposal_dispatcher.update_proposal(
                insured_proposal_id,
                proposal_obj.subject_matter,
                proposal_obj.sum_insured,
                convert_premium_frequency_to_code(proposal_obj.premium_frequency),
                proposal_obj.frequency_factor,
                true,
                current_txn_id
            );

            policy_dispatcher.update_policy_data(
                policy_obj.policy_id,
                policy_obj.subject_matter,
                policy_obj.sum_insured,
                policy_obj.premium,
                convert_premium_frequency_to_code(policy_obj.premium_frequency),
                policy_obj.frequency_factor,
                100,
                0,
                true,
                current_txn_id
            );

            let reinsurer_obj: Reinsurer = self.reinsurers.read(reinsurer_id);


            let treasury_account: ContractAddress = self.starknet_indemnify_treasury_account.read();

            let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher {
                contract_address: self.strk_contract_address.read()
            }; 

            let balance: u256 = strk_dispatcher.balance_of(treasury_account);

            assert!(balance >= ceded_premium, "Treasury Account doesn't have enough balance");

            let allowance: u256 = strk_dispatcher.allowance(treasury_account, reinsurance_payment_address);

            assert!(allowance >= ceded_premium, "Reinsurance Account is not allowed to spend enough STRK token");


            let success: bool = strk_dispatcher.transfer_from(treasury_account, reinsurance_payment_address, ceded_premium);

            assert!(success, "Reinsurance Premium Payment failed");

            let current_time: u64 = get_block_timestamp();

            let txn_info: TxInfo = get_tx_info().unbox();

            let txn_hash: felt252 = txn_info.transaction_hash;

            

            let new_reinsurance_payment: CreditReinsurance = CreditReinsurance {
                transaction_id: current_txn_id,
                insured_proposal_id: insured_proposal_id,
                insured_policy_id: insured_policy_id,
                insured: proposal_obj.proposer,
                reinsurer_id: reinsurer_id,
                reinsurance_payment_address: reinsurance_payment_address,
                reinsurer_name: reinsurer_obj.reinsurer_name,
                percentage_reinsurance: percentage_reinsurance,
                gross_sum_insured: gross_sum_insured,
                ceded_sum_insured: ceded_sum_insured,
                gross_premium: gross_premium,
                ceded_premium: ceded_premium,
                payment_date: current_time,
                updated_at: current_time,
                txn_hash: txn_hash,
                reinsurance_doc_url: "",
                payment_status_code: convert_payment_status_to_code(PaymentStatus::Successful),
                reinsurance_status_code: convert_reinsurance_status_to_code(ReinsuranceStatus::UnderReview)
            };

            self.reinsurance_setting_txns.write(current_txn_id, new_reinsurance_payment);

            let incremented_txn_id: u256 = current_txn_id + 1;

            self.next_transaction_id.write(incremented_txn_id);

            current_txn_id
        }
    
        fn update_reinsurance_premium_payment_detail(
            ref self: ContractState,
            transaction_id: u256,
            txn_hash: felt252,
            reinsurance_doc_url: ByteArray,
            payment_status_code: u8,
            reinsurance_status_code: u8
        ) {

            let updateable_txn: CreditReinsurance = self.reinsurance_setting_txns.read(transaction_id);

            let current_time: u64 = get_block_timestamp();

            let updated_txn: CreditReinsurance = CreditReinsurance {
                transaction_id: transaction_id,
                insured_proposal_id: updateable_txn.insured_proposal_id,
                insured_policy_id: updateable_txn.insured_policy_id,
                insured: updateable_txn.insured,
                reinsurer_id: updateable_txn.reinsurer_id,
                reinsurance_payment_address: updateable_txn.reinsurance_payment_address,
                reinsurer_name: updateable_txn.reinsurer_name,
                percentage_reinsurance: updateable_txn.percentage_reinsurance,
                gross_sum_insured: updateable_txn.gross_sum_insured,
                ceded_sum_insured: updateable_txn.ceded_sum_insured,
                gross_premium: updateable_txn.gross_premium,
                ceded_premium: updateable_txn.ceded_premium,
                payment_date: updateable_txn.payment_date,
                updated_at: current_time,
                txn_hash: txn_hash,
                reinsurance_doc_url: reinsurance_doc_url,
                payment_status_code: payment_status_code,
                reinsurance_status_code: reinsurance_status_code
            };

            self.reinsurance_setting_txns.write(transaction_id, updated_txn);
        }
    
        fn get_reinsurance_premium_payment_detail(
            self: @ContractState,
            transaction_id: u256
        ) -> CreditReinsuranceResponse {

            let sought_txn: CreditReinsurance = self.reinsurance_setting_txns.read(transaction_id);

            let response_obj: CreditReinsuranceResponse = CreditReinsuranceResponse {
                transaction_id: transaction_id,
                insured_proposal_id: sought_txn.insured_proposal_id,
                insured_policy_id: sought_txn.insured_policy_id,
                insured: sought_txn.insured,
                reinsurer_id: sought_txn.reinsurer_id,
                reinsurance_payment_address: sought_txn.reinsurance_payment_address,
                reinsurer_name: sought_txn.reinsurer_name,
                percentage_reinsurance: sought_txn.percentage_reinsurance,
                gross_sum_insured: sought_txn.gross_sum_insured,
                ceded_sum_insured: sought_txn.ceded_sum_insured,
                gross_premium: sought_txn.gross_premium,
                ceded_premium: sought_txn.ceded_premium,
                payment_date: sought_txn.payment_date,
                updated_at: sought_txn.updated_at,
                txn_hash: sought_txn.txn_hash,
                reinsurance_doc_url: sought_txn.reinsurance_doc_url,
                payment_status: convert_payment_code_to_status(sought_txn.payment_status_code),
                reinsurance_status: convert_reinsurance_status_code_to_status(sought_txn.reinsurance_status_code)
            };

            response_obj
        }
    
        fn initiate_claim_recovery_from_reinsurance(
            ref self: ContractState,
            reinsurance_payment_id: u256,
            insured_proposal_id: u256,
            insured_policy_id: u256,
            claim_id: u256,
            insured: ContractAddress,
            reinsurer_id: u256,
            reinsurance_payment_address: ContractAddress,
            gross_claim_amount: u256,
        ) -> u256 {
            
            let current_txn_id: u256 = self.next_transaction_id.read();

            let reinsurance_payment_obj: CreditReinsurance = self.reinsurance_setting_txns.read(reinsurance_payment_id);
            let reinsurer_obj: Reinsurer = self.reinsurers.read(reinsurer_id);

            let apportioned_claim: u256 = reinsurance_payment_obj.percentage_reinsurance.into() * gross_claim_amount;

            let current_time: u64 = get_block_timestamp();

            let new_txn: DebitReinsurance = DebitReinsurance {
                transaction_id: current_txn_id,
                reinsurance_payment_id: reinsurance_payment_id,
                insured_proposal_id: insured_proposal_id,
                insured_policy_id: insured_policy_id,
                claim_id: claim_id,
                insured: insured,
                reinsurer_id: reinsurer_id,
                reinsurance_payment_address: reinsurance_payment_address,
                reinsurer_name: reinsurer_obj.reinsurer_name,
                percentage_reinsurance: reinsurance_payment_obj.percentage_reinsurance,
                gross_sum_insured: reinsurance_payment_obj.gross_sum_insured,
                ceded_sum_insured: reinsurance_payment_obj.ceded_sum_insured,
                gross_premium: reinsurance_payment_obj.gross_premium,
                ceded_premium: reinsurance_payment_obj.ceded_premium,
                gross_claim_amount: gross_claim_amount,
                reinsurance_claim_apportionment: apportioned_claim,
                settlement_date: current_time,
                updated_at: current_time,
                txn_hash: '',
                reinsurance_doc_url: "",
                claim_discharge_voucher_url: "",
                settlement_status_code: convert_payment_status_to_code(PaymentStatus::Pending),
                reinsurance_status_code: convert_reinsurance_status_to_code(ReinsuranceStatus::Initiated)
            };

            self.reinsurance_recovery_txns.write(current_txn_id, new_txn);

            let incremented_txn_id: u256 = current_txn_id + 1;

            self.next_transaction_id.write(incremented_txn_id);

            current_txn_id
        }
    
        // fn update_claim_recovery_from_reinsurance(
        //     ref self: ContractState,
        //     transaction_id: u256,
        //     claim_id: u256,
        //     reinsurance_payment_id: u256,
        //     reinsurance_payment_address: ContractAddress,
        //     txn_hash: ByteArray,
        //     claim_discharge_voucher_url: ByteArray,
        //     settlement_status_code: u8,
        //     reinsurance_status_code: u8 
        // ) {

        // }
    
        // fn get_claim_recovery_from_reinsurance_detail(
        //     self: @ContractState,
        //     transaction_id: u256
        // ) -> DebitReinsuranceResponse {

        // }
    
        // fn create_new_reinsurer(
        //     ref self: ContractState,
        //     reinsurer_name: ByteArray,
        //     reinsurer_head_office: ByteArray,
        //     reinsurer_fiat_account: ByteArray,
        //     reinsurer_web_site: ByteArray,
        //     risk_capacity: u256,
        //     contract_type_code: u8,
        // ) -> u256 {

        // }
    
        // fn update_reinsruer_detail(
        //     ref self: ContractState,
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
        // ) {

        // }
    
        // fn get_reinsurer_by_id(
        //     self: @ContractState,
        //     reinsurer_id: u256
        // ) -> ReinsurerResponse {

        // }

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
            self.proposal_form_address.read()
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
            self.policy_minting_address.read()
        }
        
        fn set_governance_address(
            ref self: ContractState,
            governance_address: ContractAddress
        ) {
            let caller: ContractAddress = get_caller_address();
            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
            self.governance_contract_address.write(governance_address);
        }
        
        fn get_governance_address(
            self: @ContractState,
        ) -> ContractAddress {
            self.governance_contract_address.read()
        }
        
        fn set_claims_contract_address(
            ref self: ContractState,
            claims_contract_address: ContractAddress
        ) {
            let caller: ContractAddress = get_caller_address();
            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
            self.claims_contract_address.write(claims_contract_address);
        }
        
        fn get_claims_contract_address(
            self: @ContractState,
        ) -> ContractAddress {
            self.claims_contract_address.read()
        }



fn set_stindem_token_address(
    ref self: ContractState,
    stindem_token_address: ContractAddress
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.stindem_token_address.write(stindem_token_address);
}

fn get_stindem_token_address(
    self: @ContractState,
) -> ContractAddress {
    self.stindem_token_address.read()
}

fn set_current_stindem_to_strk_value(
    ref self: ContractState,
    value: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.current_stindem_to_strk_value.write(value);
}

fn get_current_stindem_to_strk_value(
    self: @ContractState,
) -> u256 {
    self.current_stindem_to_strk_value.read()
}

fn set_current_stindem_to_eth_value(
    ref self: ContractState,
    value: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.current_stindem_to_eth_value.write(value);
}

fn get_current_stindem_to_eth_value(
    self: @ContractState,
) -> u256 {
    self.current_stindem_to_eth_value.read()
}

fn set_current_stindem_to_btc_value(
    ref self: ContractState,
    value: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.current_stindem_to_btc_value.write(value);
}

fn get_current_stindem_to_btc_value(
    self: @ContractState,
) -> u256 {
    self.current_stindem_to_btc_value.read()
}

fn set_current_stindem_to_usd_value(
    ref self: ContractState,
    value: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.current_stindem_to_usd_value.write(value);
}

fn get_current_stindem_to_usd_value(
    self: @ContractState,
) -> u256 {
    self.current_stindem_to_usd_value.read()
}

fn set_current_strk_to_usd_value(
    ref self: ContractState,
    value: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.current_strk_to_usd_value.write(value);
}

fn get_current_strk_to_usd_value(
    self: @ContractState,
) -> u256 {
    self.current_strk_to_usd_value.read()
}

fn set_current_strk_to_eth_value(
    ref self: ContractState,
    value: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.current_strk_to_eth_value.write(value);
}

fn get_current_strk_to_eth_value(
    self: @ContractState,
) -> u256 {
    self.current_strk_to_eth_value.read()
}

fn set_current_strk_to_btc_value(
    ref self: ContractState,
    value: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.current_strk_to_btc_value.write(value);
}

fn get_current_strk_to_btc_value(
    self: @ContractState,
) -> u256 {
    self.current_strk_to_btc_value.read()
}

fn set_starknet_indemnify_usd_balance(
    ref self: ContractState,
    balance: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.starknet_indemnify_usd_balance.write(balance);
}

fn get_starknet_indemnify_usd_balance(
    self: @ContractState,
) -> u256 {
    self.starknet_indemnify_usd_balance.read()
}

fn set_starknet_indemnify_strk_balance(
    ref self: ContractState,
    balance: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.starknet_indemnify_strk_balance.write(balance);
}

fn get_starknet_indemnify_strk_balance(
    self: @ContractState,
) -> u256 {
    self.starknet_indemnify_strk_balance.read()
}

fn set_starknet_indemnify_stindem_balance(
    ref self: ContractState,
    balance: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.starknet_indemnify_stindem_balance.write(balance);
}

fn get_starknet_indemnify_stindem_balance(
    self: @ContractState,
) -> u256 {
    self.starknet_indemnify_stindem_balance.read()
}

fn set_starknet_indemnify_eth_balance(
    ref self: ContractState,
    balance: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.starknet_indemnify_eth_balance.write(balance);
}

fn get_starknet_indemnify_eth_balance(
    self: @ContractState,
) -> u256 {
    self.starknet_indemnify_eth_balance.read()
}

fn set_starknet_indemnify_btc_balance(
    ref self: ContractState,
    balance: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.starknet_indemnify_btc_balance.write(balance);
}

fn get_starknet_indemnify_btc_balance(
    self: @ContractState,
) -> u256 {
    self.starknet_indemnify_btc_balance.read()
}


fn set_stindem_qty_to_vote(
    ref self: ContractState,
    quantity: u256
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.stindem_qty_to_vote.write(quantity);
}

fn get_stindem_qty_to_vote(
    self: @ContractState,
) -> u256 {
    self.stindem_qty_to_vote.read()
}


fn set_strk_contract_address(
    ref self: ContractState,
    strk_contract_address: ContractAddress
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.strk_contract_address.write(strk_contract_address);
}

fn get_strk_contract_address(
    self: @ContractState,
) -> ContractAddress {
    self.strk_contract_address.read()
}


fn set_starknet_indemnify_treasury_account(
    ref self: ContractState,
    treasury_account: ContractAddress
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.starknet_indemnify_treasury_account.write(treasury_account);
}

fn get_starknet_indemnify_treasury_account(
    self: @ContractState,
) -> ContractAddress {
    self.starknet_indemnify_treasury_account.read()
}

fn set_starknet_indemnify_stindem_treasury(
    ref self: ContractState,
    stindem_treasury: ContractAddress
) {
    let caller: ContractAddress = get_caller_address();
    assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");
    self.starknet_indemnify_stindem_treasury.write(stindem_treasury);
}

fn get_starknet_indemnify_stindem_treasury(
    self: @ContractState,
) -> ContractAddress {
    self.starknet_indemnify_stindem_treasury.read()
}
    
    }


    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {

            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(DEFAULT_ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");

            self.upgradeable.upgrade(new_class_hash);
        }
    }
}
