# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::Cartafact::UploadContract,  dbclean: :after_each do

  describe "message contract" do

    context "sending with missing values should return errors" do
      let(:invalid_params) { {subjects: [], id: "", type: "", source: "" } }
      let(:error_message) { {:subjects => ["Missing attributes for subjects"], :id => ["Doc storage Identifier is blank"],
                             :type => ["Please enter document type"], :source => ["Invalid source"]}}

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(subject.call(invalid_params)).to be_a ::Dry::Validation::Result
      end

      it 'should throw errors' do
        expect(subject.call(invalid_params).errors.to_h).to eq error_message
      end
    end

    context "sending with missing keys should return errors" do

      let(:invalid_params) { {} }
      let(:error_message) {{:subjects => ["is missing"], :id => ["is missing"],
                             :type => ["is missing"], :source => ["is missing"]}}

      it 'should throw errors' do
        expect(subject.call(invalid_params).errors.to_h).to eq error_message
      end
    end

    context "sending with all keys and values should not errors" do

      let(:valid_params) {{subjects: [id: BSON::ObjectId.new.to_s, type: "notice" ],
                            id: BSON::ObjectId.new.to_s, type: "test", source: "enroll_system"}}


      it 'should return Dry::Validation::Result object' do
        expect(subject.call(valid_params)).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(subject.call(valid_params).errors.to_h).to be_empty
      end
    end

  end
end
