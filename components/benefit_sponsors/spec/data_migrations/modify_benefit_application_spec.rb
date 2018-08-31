require "rails_helper"
require File.join(File.dirname(__FILE__), "..", "..", "app", "data_migrations", "modify_benefit_application")

RSpec.describe ModifyBenefitApplication, db_clean: :after_each do

  let(:given_task_name) { "modify_benefit_application" }
  subject { ModifyBenefitApplication.new(given_task_name, double(:current_scope => nil)) }

  after :each do
    DatabaseCleaner.clean
  end

  describe "given a task name", db_clean: :after_each do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "modifying benefit application", db_clean: :after_each do

    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            title: "SHOP Benefits for #{current_effective_date.year}",
                                            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                          }
    let(:benefit_market)      { site.benefit_markets.first }
    let!(:product_package) { benefit_market_catalog.product_packages.first }

    let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let!(:security_question)  { FactoryGirl.create_default :security_question }

    let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:benefit_sponsorship) do
      FactoryGirl.create(
        :benefit_sponsors_benefit_sponsorship,
        :with_rating_area,
        :with_service_areas,
        supplied_rating_area: rating_area,
        service_area_list: [service_area],
        organization: organization,
        profile_id: organization.profiles.first.id,
        benefit_market: site.benefit_markets[0],
        employer_attestation: employer_attestation)
    end

    let(:start_on)  { current_effective_date.prev_month }
    let(:effective_period)  { start_on..start_on.next_year.prev_day }
    let!(:benefit_application) {
      application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: effective_period, aasm_state: :active)
      application.benefit_sponsor_catalog.save!
      application
    }

    let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package, is_active: true) }
    let(:benefit_group_assignment) {FactoryGirl.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package)}

    let(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id) }
    let(:census_employee) { FactoryGirl.create(:benefit_sponsors_census_employee,
      employer_profile: benefit_sponsorship.profile,
      benefit_sponsorship: benefit_sponsorship,
      benefit_group_assignments: [benefit_group_assignment]
    )}
    let(:person) { FactoryGirl.create(:person) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}

    let!(:hbx_enrollment) do
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         kind: "employer_sponsored",
                         effective_on: start_on,
                         employee_role_id: employee_role.id,
                         sponsored_benefit_package_id: benefit_package.id,
                         benefit_group_assignment_id: benefit_group_assignment.id,
                         aasm_state: 'coverage_selected'
      )
    end

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
    end

    context "terminate benefit application", db_clean: :after_each do
      let(:termination_date) { start_on.next_month.next_day }
      let(:end_on)           { start_on.next_month.end_of_month }

      before do
        allow(ENV).to receive(:[]).with("termination_notice").and_return("true")
        allow(ENV).to receive(:[]).with("action").and_return("terminate")
        allow(ENV).to receive(:[]).with("termination_date").and_return(termination_date.to_s)
        allow(ENV).to receive(:[]).with("end_on").and_return(end_on.to_s)
        subject.migrate
        benefit_application.reload
        hbx_enrollment.reload
      end

      it "should terminate the benefit application" do
        expect(benefit_application.aasm_state).to eq :terminated
      end

      it "should update end on date on benefit application" do
        expect(benefit_application.end_on).to eq end_on
      end

      it "should update end on date on benefit application" do
        expect(benefit_application.terminated_on).to eq termination_date
      end

      it "should terminate any active employee enrollments" do
        expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"
      end
      it "should terminate any active employee enrollments with termination date as on Benefit Application" do
        expect(hbx_enrollment.terminated_on).to eq end_on
      end
    end


    context "cancel benefit application", db_clean: :after_each do
      let(:past_start_on) {start_on.prev_month}
      let!(:past_effective_period) {past_start_on..past_start_on.next_year.prev_day }
      let!(:mid_plan_year_effective_date) {start_on.prev_month.prev_month}
      let!(:range_effective_period) { mid_plan_year_effective_date..mid_plan_year_effective_date.next_year.prev_day }
      let!(:draft_benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package, benefit_sponsorship: benefit_sponsorship, aasm_state: :imported, effective_period: past_effective_period)}
      let!(:import_draft_benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package, benefit_sponsorship: benefit_sponsorship, aasm_state: :imported, effective_period: range_effective_period)}

      before :each do
        allow(ENV).to receive(:[]).with('action').and_return 'cancel'
        allow(ENV).to receive(:[]).with('plan_year_start_on').and_return import_draft_benefit_application.effective_period.min.to_s
        subject.migrate
      end

      it "does not cancel non-imported draft benefit applications" do
        expect(draft_benefit_application.reload.aasm_state).to eq :imported
      end

      it "cancels import draft benefit applications" do
        expect(import_draft_benefit_application.reload.aasm_state).to eq :canceled
      end
    end

    context "Should update effective period and approve benefit application", db_clean: :after_each do
      let(:effective_date) { start_on }
      let(:new_start_date) { start_on.next_month }
      let(:new_end_date) { new_start_date + 1.year }

      before do
        allow(ENV).to receive(:[]).with("action").and_return("update_effective_period_and_approve")
        allow(ENV).to receive(:[]).with("effective_date").and_return(effective_date.to_s)
        allow(ENV).to receive(:[]).with("new_start_date").and_return(new_start_date.to_s)
        allow(ENV).to receive(:[]).with("new_end_date").and_return(new_end_date.to_s)
      end

      it "should update the benefit application" do
        benefit_application.update_attributes!(aasm_state: "draft")
        expect(benefit_application.effective_period.min.to_date).to eq start_on
        subject.migrate
        benefit_application.reload
        expect(benefit_application.start_on.to_date).to eq new_start_date
        expect(benefit_application.end_on.to_date).to eq new_end_date
        expect(benefit_application.aasm_state).to eq :approved
      end

      it "should not update the benefit application" do
        expect { subject.migrate }.to raise_error(RuntimeError)
        expect { subject.migrate }.to raise_error("No benefit application found.")
      end
    end


    context "should trigger termination notice", db_clean: :after_each do

      let(:termination_date) { start_on.next_month.next_day }
      let(:end_on)           { start_on.next_month.end_of_month }

      before do
        allow(ENV).to receive(:[]).with("termination_notice").and_return("true")
        allow(ENV).to receive(:[]).with("action").and_return("terminate")
        allow(ENV).to receive(:[]).with("termination_date").and_return(termination_date.to_s)
        allow(ENV).to receive(:[]).with("end_on").and_return(end_on.to_s)
      end

      let(:model_instance) { benefit_application }

      context "should trigger termination notice to employer and employees" do
        it "should trigger model event" do
          model_instance.class.observer_peers.keys.each do |observer|
            expect(observer).to receive(:notifications_send) do |instance, model_event|
              expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :group_advance_termination_confirmation, :klass_instance => model_instance, :options => {})
            end
          end
          subject.migrate
        end
      end
    end
  end
end
