require "rails_helper"
require 'lib/api/v1/support/mobile_employer_data'

RSpec.describe Api::V1::Mobile::Employee, dbclean: :after_each do
  include_context 'employer_data'

  context 'Enrollments' do

    it 'should return active employer sponsored health enrollments' do
      enrollment = Api::V1::Mobile::Enrollment.new
      hbx_enrollment1 = HbxEnrollment.new kind: 'employer_sponsored', coverage_kind: 'health', is_active: true, submitted_at: Time.now
      hbx_enrollment2 = HbxEnrollment.new kind: 'employer_sponsored', coverage_kind: 'health', is_active: true
      hbx_enrollments = [hbx_enrollment1, hbx_enrollment2]

      enrollment.instance_variable_set(:@all_enrollments, hbx_enrollments)
      hes = enrollment.send(:active_employer_sponsored_health_enrollments)
      expect(hes).to be_a_kind_of Array
      expect(hes.size).to eq 1
      expect(hes.pop).to be_a_kind_of HbxEnrollment
    end

    it 'should return employee enrollments' do
      assignments = {active: benefit_group_assignment, renewal: benefit_group_assignment}
      enrollments = Api::V1::Mobile::Enrollment.new(assignments: assignments).employee_enrollments
      expect(enrollments).to be_a_kind_of Hash
      expect(enrollments).to include(:active, :renewal)

      active = enrollments[:active]
      renewal = enrollments[:renewal]
      expect(active).to include('health', 'dental')
      expect(renewal).to include('health', 'dental')

      active_health, renewal_health = active['health'], renewal['health']
      active_dental, renewal_dental = active['dental'], renewal['dental']
      expect(active_health).to include(:status, :employer_contribution, :employee_cost, :total_premium, :plan_name,
                                       :plan_type, :metal_level, :benefit_group_name)
      expect(renewal_health).to include(:status, :employer_contribution, :employee_cost, :total_premium, :plan_name,
                                        :plan_type, :metal_level, :benefit_group_name)
      expect(active_dental).to include(:status)
      expect(renewal_dental).to include(:status)
      expect(active_health[:status]).to eq 'Enrolled'
      expect(renewal_health[:status]).to eq 'Enrolled'
      expect(active_dental[:status]).to eq 'Not Enrolled'
      expect(renewal_dental[:status]).to eq 'Not Enrolled'
    end

    it 'should return benefit group assignments' do
      enrollment = Api::V1::Mobile::Enrollment.new
      enrollment.instance_variable_set(:@all_enrollments, [shop_enrollment_barista])
      bgas = enrollment.send(:bg_assignment_ids, HbxEnrollment::ENROLLED_STATUSES)
      expect(bgas).to be_a_kind_of Array
      expect(bgas.size).to eq 1
      expect(bgas.pop).to be_a_kind_of BSON::ObjectId

      expect{enrollment.benefit_group_assignment_ids(HbxEnrollment::ENROLLED_STATUSES, [], [])}.to raise_error(LocalJumpError)
      enrollment.benefit_group_assignment_ids HbxEnrollment::ENROLLED_STATUSES, [], [] do |enrolled_ids, waived_ids, terminated_ids|
        expect(enrolled_ids).to be_a_kind_of Array
        expect(enrolled_ids.size).to eq 1
        expect(enrolled_ids.pop).to be_a_kind_of BSON::ObjectId
      end
    end

    it 'should initialize enrollments' do
      enrollment = Api::V1::Mobile::Enrollment.new
      enrollments = enrollment.send(:initialize_enrollment, benefit_group_assignment, 'health')
      expect(enrollments).to be_a_kind_of Array
      expect(enrollments.shift).to be_a_kind_of HbxEnrollment
      expect(enrollments.shift).to include(:status, :employer_contribution, :employee_cost, :total_premium, :plan_name,
                                           :plan_type, :metal_level, :benefit_group_name)
      enrollments = enrollment.send(:initialize_enrollment, benefit_group_assignment, 'dental')
      expect(enrollments).to be_a_kind_of Array
      expect(enrollments.pop).to include(:status)
    end

    it 'should return the status label for enrollment status' do
      enrollment = Api::V1::Mobile::Enrollment.new
      expect(enrollment.send(:status_label_for, 'coverage_terminated')).to eq 'Terminated'
      expect(enrollment.send(:status_label_for, 'auto_renewing')).to eq 'Renewing'
      expect(enrollment.send(:status_label_for, 'inactive')).to eq 'Waived'
      expect(enrollment.send(:status_label_for, 'coverage_selected')).to eq 'Enrolled'
    end

  end

end