# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::OfficeLocations::PhoneContract do

  let(:missing_params)   { {area_code: '123'} }
  let(:error_message)    { {:kind => ['is missing'], :number => ['is missing']} }

  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message }
    end

    context "sending all parameters with invalid kind and number should fail validation with errors" do
      let(:invalid_params) { missing_params.merge({kind: 'test', number: '123456'})}

      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it {
        expect(subject.call(invalid_params).errors.to_h).to eq({:number=>["Invalid Phones: Number can't be blank"], :kind=>["Invalid Phones: kind not valid"]})
      }
    end

  end

  describe "Given valid parameters" do
    let(:valid_params) { missing_params.merge({kind: 'home', number: '1234567'})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end
  end
end
