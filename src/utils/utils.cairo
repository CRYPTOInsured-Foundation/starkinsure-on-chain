use crate::enums::enums::*;

use crate::enums::enums::ClaimStatus;
use crate::enums::enums::UpdateType;
use crate::enums::enums::BurnReason;

pub fn convert_rejection_reason_to_code(reason: RejectionReason) -> u8 {

    let code: u8 = match reason {
        RejectionReason::IncompleteProposal => 0,
        RejectionReason::Misrepresentation => 1,
        RejectionReason::NonDisclosure => 2,
        RejectionReason::RiskTooHigh => 3,
        RejectionReason::LacksInsurableInterest => 4,
        RejectionReason::PoorMoralHazard => 5,
        RejectionReason::PoorPhysicalHazard => 6,
        RejectionReason::UndisclosedReason => 7,
        RejectionReason::NotRejected => 8,
        RejectionReason::LacksKYC => 9,
        RejectionReason::InvalidReason => 100
    };

    code
}

pub fn convert_rejection_code_to_reason(code: u8) -> RejectionReason {
    let reason: RejectionReason = match code {
        0 => RejectionReason::IncompleteProposal,
        1 => RejectionReason::Misrepresentation,
        2 => RejectionReason::NonDisclosure,
        3 => RejectionReason::RiskTooHigh,
        4 => RejectionReason::LacksInsurableInterest,
        5 => RejectionReason::PoorMoralHazard,
        6 => RejectionReason::PoorPhysicalHazard,
        7 => RejectionReason::UndisclosedReason,
        8 => RejectionReason::NotRejected,
        9 => RejectionReason::LacksKYC,
        _ => RejectionReason::InvalidReason
    };

    reason
}


pub fn convert_proposal_status_to_code(status: ProposalStatus) -> u8 {
    let code: u8 = match status {
        ProposalStatus::Draft => 0,
        ProposalStatus::Submitted => 1,
        ProposalStatus::UnderReview => 2,
        ProposalStatus::Approved => 3,
        ProposalStatus::Rejected => 4,
        ProposalStatus::Expired => 5,
        ProposalStatus::InvalidStatus => 100
    };

    code
}

pub fn convert_proposal_code_to_status(code: u8) -> ProposalStatus {

    let status: ProposalStatus = match code {
        0 => ProposalStatus::Draft,
        1 => ProposalStatus::Submitted,
        2 => ProposalStatus::UnderReview,
        3 => ProposalStatus::Approved,
        4 => ProposalStatus::Rejected,
        5 => ProposalStatus::Expired,
        _ => ProposalStatus::InvalidStatus
    };

    status
}


pub fn convert_policy_code_to_class (code: u8) -> PolicyClass {

    let policy_class: PolicyClass = match code {

        0 => PolicyClass::TravelInsurance,
        1 => PolicyClass::BlockchainExploitInsurance,
        2 => PolicyClass::FireInsurance,
        3 => PolicyClass::MotorInsurance,
        4 => PolicyClass::PersonalAccidentInsurance,
        5 => PolicyClass::HealthInsurance,
        _ => PolicyClass::InvalidClassOfInsurance
    };

    policy_class
}


pub fn convert_policy_class_to_code (policy_class: PolicyClass) -> u8 {
    let code: u8 = match policy_class {
        PolicyClass::TravelInsurance => 0,
        PolicyClass::BlockchainExploitInsurance => 1,
        PolicyClass::FireInsurance => 2,
        PolicyClass::MotorInsurance => 3,
        PolicyClass::PersonalAccidentInsurance => 4,
        PolicyClass::HealthInsurance => 5,
        PolicyClass::InvalidClassOfInsurance => 100,        
    };

    code
}

pub fn convert_premium_frequency_to_code(frequency: PremiumFrequency) -> u8 {
    
    let code: u8 = match frequency {
        PremiumFrequency::Monthly => 0,
        PremiumFrequency::Quarterly => 1,
        PremiumFrequency::HalfYearly => 2,
        PremiumFrequency::Annually => 3,
        PremiumFrequency::InvalidFrequency => 100
    };

    code 
}

pub fn convert_premium_code_to_frequency(code: u8) -> PremiumFrequency {

    let frequency: PremiumFrequency = match code {
        0 => PremiumFrequency::Monthly,
        1 => PremiumFrequency::Quarterly,
        2 => PremiumFrequency::HalfYearly,
        3 => PremiumFrequency::Annually,
        _ => PremiumFrequency::InvalidFrequency
    };

    frequency
}


pub fn convert_code_to_burn_reason (reason_index: u8) -> BurnReason {

    let burn_reason: BurnReason = match reason_index {
        0 => BurnReason::PolicyExpired,
        1 => BurnReason::PolicyCancelled,
        2 => BurnReason::FraudulentClaim,
        3 => BurnReason::RecklessRepresentation,
        _ => BurnReason::InvalidReason

    };

    burn_reason
}  


pub fn convert_burn_reason_to_code (burn_reason: BurnReason) -> u8 {

    let code: u8 = match burn_reason {
        BurnReason::PolicyExpired => 0,
        BurnReason::PolicyCancelled => 1,
        BurnReason::FraudulentClaim => 2,
        BurnReason::RecklessRepresentation => 3,
        BurnReason::InvalidReason => 100

    };

    code
}  

pub fn convert_code_to_policy_update_type (code: u8) -> UpdateType {

    let mut update_type: UpdateType = match code {
        0 => UpdateType::Endorsement,
        1 => UpdateType::Renewal,
        _ => UpdateType::InvalidUpdateType
    };

    update_type
}


pub fn convert_policy_update_type_to_code (update_type: UpdateType) -> u8 {

    let mut code: u8 = match update_type {
        UpdateType::Endorsement => 0,
        UpdateType::Renewal => 1,
        UpdateType::InvalidUpdateType => 100
    };

    code
}




pub fn convert_claim_status_to_code (status: ClaimStatus) -> u8 {

    let code: u8 = match status {
        ClaimStatus::Submitted => 0,
        ClaimStatus::UnderReview => 1,
        ClaimStatus::Approved => 2,
        ClaimStatus::Repudiated => 3,
        ClaimStatus::Settled => 4,
        ClaimStatus::InvalidStatus => 100
    };

    code 
}


pub fn convert_claim_code_to_status (code: u8) -> ClaimStatus {

    let status: ClaimStatus = match code {
        0 => ClaimStatus::Submitted,
        1 => ClaimStatus::UnderReview,
        2 => ClaimStatus::Approved,
        3 => ClaimStatus::Repudiated,
        4 => ClaimStatus::Settled,
        _ => ClaimStatus::InvalidStatus
    };

    status
}

pub fn convert_repudiation_reason_to_code (reason: ClaimRepudiationReason) -> u8 {

    let code: u8 = match reason {
        ClaimRepudiationReason::NonDisclosure => 0,
        ClaimRepudiationReason::Misrepresentation => 1,
        ClaimRepudiationReason::PolicyExclusion => 2,
        ClaimRepudiationReason::FraudulentClaim => 3,
        ClaimRepudiationReason::LapsedPolicy => 4,
        ClaimRepudiationReason::PolicyTermsAndConditionsBreach => 5,
        ClaimRepudiationReason::InsufficientDocumentation => 6,
        ClaimRepudiationReason::IllegalClaim => 7,
        ClaimRepudiationReason::LackOfInsurableInterest => 8,
        ClaimRepudiationReason::NotRepudiated => 9,
        ClaimRepudiationReason::InvalidRepudiationReason => 100
    };

    code
}

pub fn convert_repudiation_code_to_reason (code: u8) -> ClaimRepudiationReason {

    let reason: ClaimRepudiationReason = match code {
        0 => ClaimRepudiationReason::NonDisclosure,
        1 => ClaimRepudiationReason::Misrepresentation,
        2 => ClaimRepudiationReason::PolicyExclusion,
        3 => ClaimRepudiationReason::FraudulentClaim,
        4 => ClaimRepudiationReason::LapsedPolicy,
        5 => ClaimRepudiationReason::PolicyTermsAndConditionsBreach,
        6 => ClaimRepudiationReason::InsufficientDocumentation,
        7 => ClaimRepudiationReason::IllegalClaim,
        8 => ClaimRepudiationReason::LackOfInsurableInterest,
        9 => ClaimRepudiationReason::NotRepudiated,
        _ => ClaimRepudiationReason::InvalidRepudiationReason
    };

    reason

}



pub fn convert_claim_type_to_code (claim_type: ClaimType) -> u8 {

    let code: u8 = match claim_type {
        ClaimType::Small => 0,
        ClaimType::Medium => 1,
        ClaimType::Large => 2,
        ClaimType::Catastrophic => 3,
        ClaimType::Undetermined => 4,
        ClaimType::InvalidClaimType => 100
    };

    code
}


pub fn convert_claim_code_to_type (code: u8) -> ClaimType {
    
    let claim_type: ClaimType = match code {
        0 => ClaimType::Small,
        1 => ClaimType::Medium,
        2 => ClaimType::Large,
        3 => ClaimType::Catastrophic,
        4 => ClaimType::Undetermined,
        _ => ClaimType::InvalidClaimType

    };

    claim_type
}


pub fn convert_payment_status_to_code(status: PaymentStatus) -> u8 {

    let code: u8 = match status {

        PaymentStatus::Pending => 0,
        PaymentStatus::Processing => 1,
        PaymentStatus::Successful => 2,
        PaymentStatus::Failed => 3,
        PaymentStatus::Cancelled => 4,
        PaymentStatus::Refunded => 5,
        PaymentStatus::InvalidPaymentStatus => 100
    };

    code
}

pub fn convert_payment_code_to_status(code: u8) -> PaymentStatus {

    let status: PaymentStatus = match code {
        0 => PaymentStatus::Pending,
        1 => PaymentStatus::Processing,
        2 => PaymentStatus::Successful,
        3 => PaymentStatus::Failed,
        4 => PaymentStatus::Cancelled,
        5 => PaymentStatus::Refunded,
        _ => PaymentStatus::InvalidPaymentStatus
    };

    status
}




pub fn convert_claims_settlement_source_to_code(source: ClaimsPaymentSource) -> u8 {

    let code: u8 = match source {
        ClaimsPaymentSource::Reserve => 0,
        ClaimsPaymentSource::Reinsurance => 1,
        ClaimsPaymentSource::InvestorsPool => 2,
        ClaimsPaymentSource::Mixed => 3,
        ClaimsPaymentSource::InvalidPaymentSource => 100
    };

    code
}


pub fn convert_claims_settlement_source_code_to_source(code: u8) -> ClaimsPaymentSource {

    let source: ClaimsPaymentSource = match code {
        0 => ClaimsPaymentSource::Reserve,
        1 => ClaimsPaymentSource::Reinsurance,
        2 => ClaimsPaymentSource::InvestorsPool,
        3 => ClaimsPaymentSource::Mixed,
        _ => ClaimsPaymentSource::InvalidPaymentSource
    };

    source
}




pub fn convert_reinsurance_status_to_code(status: ReinsuranceStatus) -> u8 {

    let code: u8 = match status {
        ReinsuranceStatus::Initiated => 0,
        ReinsuranceStatus::Submitted => 1,
        ReinsuranceStatus::Acknowledged => 2,
        ReinsuranceStatus::UnderReview => 3,
        ReinsuranceStatus::Pending => 4,
        ReinsuranceStatus::Quoted => 5,
        ReinsuranceStatus::Negotiated => 6,
        ReinsuranceStatus::Approved => 7,
        ReinsuranceStatus::Rejected => 8,
        ReinsuranceStatus::Withdrawn => 9,
        ReinsuranceStatus::Expired => 10,
        ReinsuranceStatus::InvalidReinsuranceStatus => 100
    };

    code
}


pub fn convert_reinsurance_status_code_to_status(code: u8) -> ReinsuranceStatus {

    let status: ReinsuranceStatus = match code {
        0 => ReinsuranceStatus::Initiated,
        1 => ReinsuranceStatus::Submitted,
        2 => ReinsuranceStatus::Acknowledged,
        3 => ReinsuranceStatus::UnderReview,
        4 => ReinsuranceStatus::Pending,
        5 => ReinsuranceStatus::Quoted,
        6 => ReinsuranceStatus::Negotiated,
        7 => ReinsuranceStatus::Approved,
        8 => ReinsuranceStatus::Rejected,
        9 => ReinsuranceStatus::Withdrawn,
        10 => ReinsuranceStatus::Expired,
        _ => ReinsuranceStatus::InvalidReinsuranceStatus
    };

    status
}

pub fn convert_reinsurance_contract_type_to_code(contract_type: ReinsuranceContractType) -> u8 {
    
    let code: u8 = match contract_type {
        ReinsuranceContractType::Treaty => 0,
        ReinsuranceContractType::Facultative => 1,
        ReinsuranceContractType::InvalidContractType => 100,
    };

    code
}

pub fn convert_reinsurance_contract_code_to_type(code: u8) -> ReinsuranceContractType {

    let contract_type: ReinsuranceContractType = match code {
        0 => ReinsuranceContractType::Treaty,
        1 => ReinsuranceContractType::Facultative,
        _ => ReinsuranceContractType::InvalidContractType
    };

    contract_type
}



pub fn is_claim_approved_for_settlement(is_risk_analytics_approved: bool, is_governance_approved: bool) -> bool {
        
    if is_risk_analytics_approved {
        return true;
    } else if is_governance_approved {
        return true;
    } else {
        return false;
    }
}


pub fn is_proposal_approved_for_premium_payment(is_risk_analytics_approved: bool, is_governance_approved: bool) -> bool {
        
    if is_risk_analytics_approved {
        return true;
    } else if is_governance_approved {
        return true;
    } else {
        return false;
    }
}