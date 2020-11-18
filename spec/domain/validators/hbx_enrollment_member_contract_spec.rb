# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::HbxEnrollmentMemberContract, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  let(:enrollment_member_params) do
    { applicant_id: BSON::ObjectId.new,
      is_subscriber: true,
      eligibility_date: TimeKeeper.date_of_record,
      coverage_start_on: TimeKeeper.date_of_record}
  end

  context 'success case' do
    before do
      @result = subject.call(enrollment_member_params)
    end

    it 'should return success' do
      expect(@result.success?).to be_truthy
    end

    it 'should not have any errors' do
      expect(@result.errors.empty?).to be_truthy
    end
  end

  context 'failure case' do
    context 'missing a mandatory attribute' do
      before do
        @result = subject.call(enrollment_member_params.except(:applicant_id))
      end

      it 'should return failure' do
        expect(@result.failure?).to be_truthy
      end

      it 'should have any errors' do
        expect(@result.errors.empty?).to be_falsy
      end

      it 'should return error message' do
        expect(@result.errors.messages.first.text).to eq('is missing')
      end
    end
  end
end