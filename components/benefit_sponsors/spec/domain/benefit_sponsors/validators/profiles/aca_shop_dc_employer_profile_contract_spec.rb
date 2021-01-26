# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::Profiles::AcaShopDcEmployerProfileContract do

  let(:address) { {kind: 'primary', address_1: 'test', city: 'fair', state: 'DC', zip: '22001'} }
  let(:phone) { {kind: 'home', area_code: '123', number: '1234567'} }
  let(:error_message)    { {:contact_method => ['is missing'], :is_benefit_sponsorship_eligible =>["is missing"]} }
  let(:params)   { {office_locations: [address: address, phone: phone]} }




  describe "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(params).failure?).to be_truthy }
      it { expect(subject.call(params).errors.to_h).to eq error_message }
    end

    context "sending parameters with invalid value should fail validation with errors" do
      let(:invalid_params) {params.merge({contact_method: :electronic_only, is_benefit_sponsorship_eligible: false})}

      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).errors.to_h).to eq(:is_benefit_sponsorship_eligible => ["Benefit Sponsorship should be true"]) }
    end
  end

  describe "Given valid parameters" do
    let(:valid_params) { params.merge({contact_method: :electronic_only, is_benefit_sponsorship_eligible: true})}

    context "with required params" do
      it "should pass validation" do
        expect(subject.call(valid_params).success?).to be_truthy
        expect(subject.call(valid_params).to_h).to eq valid_params
      end
    end
  end
end
