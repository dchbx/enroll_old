# frozen_string_literal: true

# Helper for creating Financial Assistance engine related data from CSV file
module GoldenSeedFinancialAssistanceHelper
  def create_and_return_fa_application(case_info_hash = nil)
    application = FinancialAssistance::Application.new
    application.family_id = case_info_hash[:family_record].id
    application.is_joint_tax_filing = case_info_hash[:person_attributes][:tax_filing_status].downcase == 'joint'
    application.save!
    application
  end

  # TODO: NEED TO DO MEDICAID AND OTHER STUFF
  def create_and_return_fa_applicant(case_info_hash, is_primary_applicant = nil)
    applicant = case_info_hash[:fa_application].applicants.build
    target_person = case_info_hash[:person_attributes][:current_target_person]
    applicant.is_primary_applicant = is_primary_applicant
    applicant.first_name = target_person.first_name
    applicant.middle_name = target_person.middle_name
    applicant.last_name = target_person.last_name
    applicant.gender = target_person.gender
    applicant.dob = target_person.dob
    applicant.is_consumer_role = target_person.consumer_role.present?
    applicant.is_joint_tax_filing = case_info_hash[:person_attributes][:tax_filing_status].downcase == 'joint'
    applicant.is_required_to_file_taxes = ["non_filer", "dependent"].exclude?(case_info_hash[:person_attributes][:tax_filing_status].downcase)
    applicant.tax_filer_kind = case_info_hash[:person_attributes][:tax_filing_status].downcase
    applicant.claimed_as_tax_dependent_by = case_info_hash[:fa_application].applicants.all.detect(&:is_primary_applicant)&.id
    # TODO: Need to refactor this once dc resident is refactored
    applicant.has_fixed_address = case_info_hash[:person_attributes][:current_target_person].send(:is_homeless?)
    applicant.is_living_in_state = case_info_hash[:person_attributes][:current_target_person].send(:is_dc_resident?)
    applicant.save!
    applicant
  end

  def create_fa_relationships(case_array = nil)
    application = case_array[1][:fa_application]
    primary_applicant = application.applicants.detect(&:is_primary_applicant)
    applicants = case_array[1][:fa_applicants].reject { |applicant| applicant == primary_applicant }
    return if applicants.blank?
    applicants.each do |applicant|
      relationship_to_primary = applicant[:relationship_to_primary].downcase
      application.relationships.create!(
        applicant_id: applicant[:applicant_record].id,
        relative_id: primary_applicant.id,
        kind: relationship_to_primary
      )
      application.relationships.create!(
        applicant_id: primary_applicant.id,
        relative_id: applicant[:applicant_record].id,
        kind: FinancialAssistance::Relationship::INVERSE_MAP[relationship_to_primary]
      )
      binding.irb
    end
  end

  # TODO: NEED TO DO MEDICAID AND OTHER STUFF
  def add_applicant_income(case_info_hash)
    return nil if case_info_hash[:person_attributes][:tax_filing_status] == 'non_filer' || case_info_hash[:person_attributes][:frequency].downcase == 'n/a'
    income = case_info_hash[:target_fa_applicant].incomes.build
    income.amount = case_info_hash[:person_attributes][:amount]
    income.frequency_kind = case_info_hash[:person_attributes][:frequency].downcase
    income.start_on = case_info_hash[:person_attributes][:from]
    income.save!
    income
  end
end
