# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Operations::HbxEnrollments::Reinstate, :type => :model, dbclean: :around_each do
  describe 'initial employer',  dbclean: :around_each do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month.prev_year }
    let(:effective_on) { current_effective_date }
    let(:hired_on) { TimeKeeper.date_of_record.prev_year - 3.months }
    let(:employee_created_at) { hired_on }
    let(:employee_updated_at) { employee_created_at }
    let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
    let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
    let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}
    let(:aasm_state) { :active }
    let(:census_employee) do
      create(:census_employee,
             :with_active_assignment,
             benefit_sponsorship: benefit_sponsorship,
             benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id,
             benefit_group: current_benefit_package,
             hired_on: hired_on,
             created_at: employee_created_at,
             updated_at: employee_updated_at)
    end
    let!(:family) do
      person = FactoryBot.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
      employee_role = FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)
      census_employee.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
    end
    let!(:employee_role){census_employee.employee_role}
    let(:enrollment_kind) { 'open_enrollment' }
    let(:special_enrollment_period_id) { nil }
    let(:covered_individuals) { family.family_members }
    let(:person) { family.primary_applicant.person }
    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: covered_individuals,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        family: family,
                        effective_on: effective_on,
                        enrollment_kind: enrollment_kind,
                        kind: 'employer_sponsored',
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: current_benefit_package.id,
                        sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                        employee_role_id: employee_role.id,
                        product: sponsored_benefit.reference_product,
                        rating_area_id: BSON::ObjectId.new,
                        benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
    end

    before do
      census_employee.terminate_employment(effective_on.next_day)
      enrollment.reload
      census_employee.reload
    end

    context 'when enrollment reinstated', dbclean: :around_each do
      let!(:new_bga) do
        current_bga = enrollment.census_employee.benefit_group_assignments.first
        bga_params = current_bga.serializable_hash.deep_symbolize_keys.except(:_id, :workflow_state_transitions)
        bga_params.merge!({start_on: enrollment.terminated_on.next_day})
        enrollment.census_employee.benefit_group_assignments << ::BenefitGroupAssignment.new(bga_params)
        enrollment.census_employee.save!
      end

      context 'for a terminated enrollment' do
        before do
          @reinstated_enrollment = subject.call({hbx_enrollment: enrollment}).success
        end

        it 'should build reinstated enrollment' do
          expect(@reinstated_enrollment.kind).to eq enrollment.kind
          expect(@reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          expect(@reinstated_enrollment.product_id).to eq enrollment.product_id
        end

        it 'should return enrollment in coverage_selected state' do
          expect(@reinstated_enrollment.aasm_state).to eq 'coverage_selected'
        end

        it 'should have continuous coverage' do
          expect(@reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
        end

        it 'should give same member coverage begin date as base enrollment' do
          enrollment_member = @reinstated_enrollment.hbx_enrollment_members.first
          expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
          expect(enrollment_member.eligibility_date).to eq @reinstated_enrollment.effective_on
          expect(@reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
        end
      end

      context 'for a waived enrollment' do
        before do
          enrollment.update_attributes!(aasm_state: 'shopping', terminate_reason: 'retroactive_canceled')
          enrollment.waive_coverage!
          enrollment.cancel_coverage!
          @result = subject.call({hbx_enrollment: enrollment}).success
        end

        it 'should transition to inactive' do
          expect(@result.aasm_state).to eq('inactive')
        end
      end
    end

    context 'when benefit group assignment not found' do
      before do
        new_enr = enrollment.dup
        new_enr.assign_attributes({effective_on: enrollment.terminated_on.next_day})
        new_enr.save!
        @result = subject.call({hbx_enrollment: enrollment})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq("Active Benefit Group Assignment does not exist for the effective_on: #{enrollment.terminated_on.next_day}")
      end
    end

    context 'overlapping enrollment exists' do
      let!(:new_bga) do
        current_bga = enrollment.census_employee.benefit_group_assignments.first
        bga_params = current_bga.serializable_hash.deep_symbolize_keys.except(:_id, :workflow_state_transitions)
        bga_params.merge!({start_on: enrollment.terminated_on.next_day})
        enrollment.census_employee.benefit_group_assignments << ::BenefitGroupAssignment.new(bga_params)
        enrollment.census_employee.save!
      end

      before do
        new_enr = enrollment.dup
        new_enr.assign_attributes({effective_on: enrollment.terminated_on.next_day})
        new_enr.save!
        @result = subject.call({hbx_enrollment: enrollment})
      end

      it 'should return a failure with a message' do
        expect(@result.failure).to eq('Overlapping coverage exists for this family in current year.')
      end
    end
  end

  describe 'age_off_dependents' do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'
    let(:benefit_package) {initial_application.benefit_packages.first}
    let!(:person) {FactoryBot.create(:person, :with_employee_role)}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let!(:family_member1) {family.family_members.first}
    let!(:family_member2) {family.family_members.second}
    let!(:family_member3) {family.family_members.last}
    let!(:census_employee) do
      create(:census_employee,
             :with_active_assignment,
             benefit_sponsorship: benefit_sponsorship,
             benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id,
             benefit_group: benefit_package,
             hired_on: TimeKeeper.date_of_record.prev_year - 3.months)
    end
    let!(:employee_role) {FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)}
    let(:shop_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: family.latest_household,
                        coverage_kind: "health",
                        family: family,
                        kind: "employer_sponsored",
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: benefit_package.id,
                        sponsored_benefit_id: benefit_package.sponsored_benefits[0].id,
                        product: benefit_package.sponsored_benefits[0].reference_product,
                        employee_role_id: employee_role.id,
                        rating_area_id: BSON::ObjectId.new)
    end
    let!(:enr_mem1) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member1.id, is_subscriber: family_member1.is_primary_applicant, hbx_enrollment: shop_enrollment) }
    let!(:enr_mem2) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member2.id, is_subscriber: family_member2.is_primary_applicant, hbx_enrollment: shop_enrollment) }
    let!(:enr_mem3) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member3.id, is_subscriber: family_member3.is_primary_applicant, hbx_enrollment: shop_enrollment) }

    context 'shop market' do
      before do
        allow(::EnrollRegistry[:aca_shop_dependent_age_off].settings[0]).to receive(:item).and_return(:monthly)
        initial_application.update_attributes(effective_period: Date.new(2020,1,1)..Date.new(2020,12,31))
        shop_enrollment.update_attributes(aasm_state: :coverage_terminated, terminated_on: Date.new(2020, 8,31))
        enr_mem2.person.update_attributes(dob: Date.new(1994, 8, 26))
        enr_mem3.person.update_attributes(dob: Date.new(1994.year, 9, 26))
        census_employee.benefit_group_assignments << BenefitGroupAssignment.new(start_on: Date.new(2020, 9, 1), benefit_package: benefit_package)
      end
      it 'should create new enrollment' do
        family = shop_enrollment.family
        expect(family.hbx_enrollments.count).to eq 1
        subject.call({hbx_enrollment: shop_enrollment})
        shop_enrollment.reload
        expect(family.hbx_enrollments.count).to eq 3
      end
      it 'should drop dependents who are > 26 and create a new enrollment' do
        family = shop_enrollment.family
        expect(family.hbx_enrollments.coverage_enrolled.count).to eq 0
        subject.call({hbx_enrollment: shop_enrollment})
        shop_enrollment.reload
        expect(family.hbx_enrollments.coverage_enrolled.count).to eq 1
        expect(family.hbx_enrollments.coverage_enrolled.first.hbx_enrollment_members.count).to eq 1
      end
    end
  end
end