# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::ExemptOrganization do

  context "Given valid required parameters" do

    let(:contract)      { BenefitSponsors::Validators::Organizations::ExemptOrganizationContract.new }
    let(:phone) do
      {
        kind: "work", area_code: "483", number: "7897489", full_phone_number: "4837897489"
      }
    end

    let(:address) do
      {
        kind: 'primary', address_1: "dc", address_2: "dc", city: "dc", state: "dc", zip: "12345"
      }
    end

    let(:office_location) do
      {
        is_primary: true, address: address, phone: phone
      }
    end

    let(:profile) do
      {
        is_benefit_sponsorship_eligible: false, contact_method: :test, corporate_npn: "1234567",
        office_locations: [office_location]
      }
    end

    let(:required_params_for_contract) do
      {
        legal_name: 'abc_organization', entity_kind: :limited_liability_corporation,
        dba: nil,  profile: profile
      }
    end

    let(:required_params_for_entity) do
      {
        legal_name: 'abc_organization', entity_kind: :limited_liability_corporation,
        site_id: BSON::ObjectId.new, dba: nil, home_page: nil, profiles: [profile]
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params_for_contract).to_h).to eq required_params_for_contract
      end

      it "should create new Organization instance" do
        expect(described_class.new(required_params_for_entity)).to be_a BenefitSponsors::Entities::ExemptOrganization
      end
    end
  end
end