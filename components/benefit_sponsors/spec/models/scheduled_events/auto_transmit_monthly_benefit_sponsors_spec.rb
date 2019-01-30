require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"


module BenefitSponsors
  RSpec.describe "initial employer monthly transmission", dbclean: :after_each do

    let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_cca_site_with_hbx_profile_and_benefit_market }
    let!(:previous_rating_area) { create_default(:benefit_markets_locations_rating_area, active_year: Date.current.year - 1) }
    let!(:previous_service_area) { create_default(:benefit_markets_locations_service_area, active_year: Date.current.year - 1) }
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let!(:service_area) { create_default(:benefit_markets_locations_service_area) }

    describe "initial employer monthly transmission for the month MARCH:
       - employer A came as initial employer :
         - published benefit application
         - Open Enrollment Closed
         - binder paid

       - employer B came as initial employer:
         - published benefit application
         - Open Enrollment Closed
         - binder not paid.

        - employer C came as late initial employer :
         - published benefit application
         - Open Enrollment Closed
         - binder paid after employer monthly transmission date i.e 26th

       - employer D came as late initial employer :
         - published benefit application
         - Open Enrollment Closed
         - binder paid after employer monthly transmission date i.e 27th

       - employer E came as late initial employer :
         - published benefit application
         - Open Enrollment Closed
         - binder paid after employer monthly transmission date i.e 28th

       - employer F came as late initial employer :
         - published benefit application
         - Open Enrollment Closed
         - binder paid after employer monthly transmission date i.e 29th

       - employer G came as late initial employer :
         - published benefit application
         - Open Enrollment Closed
         - binder paid after employer monthly transmission date i.e 30th

       - employer H came as late initial employer :
         - published benefit application
         - Open Enrollment Closed
         - binder paid after employer monthly transmission date i.e 31th
    ", dbclean: :after_each do

      let(:initial_application_state)       { :active }
      let!(:this_year)                       { TimeKeeper.date_of_record.year }
      let(:april_effective_date)            { Date.new(this_year,4,1) }

      let!(:employer_A)                 { create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                                     :with_initial_benefit_application, initial_application_state: :enrollment_eligible,
                                                     default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: :initial_enrollment_eligible)
      }

      let!(:employer_B)                 { create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                                 :with_initial_benefit_application, initial_application_state: :enrollment_ineligible,
                                                 default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: :initial_enrollment_ineligible)
      }

      let!(:employer_C)                 { create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                                 :with_initial_benefit_application, initial_application_state: :enrollment_closed,
                                                 default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: :initial_enrollment_closed)

      }

      let!(:employer_D)                 { create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                                 :with_initial_benefit_application, initial_application_state: :enrollment_closed,
                                                 default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: :initial_enrollment_closed)
      }

      let!(:employer_E)                 { create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                                 :with_initial_benefit_application, initial_application_state: :enrollment_closed,
                                                 default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: :initial_enrollment_closed)
      }
      let!(:employer_F)                 { create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                                 :with_initial_benefit_application, initial_application_state: :enrollment_closed,
                                                 default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: :initial_enrollment_closed)
      }
      let!(:employer_G)                 { create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                                 :with_initial_benefit_application, initial_application_state: :enrollment_closed,
                                                 default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: :initial_enrollment_closed)
      }
      let!(:employer_H)                 { create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                                 :with_initial_benefit_application, initial_application_state: :enrollment_closed,
                                                 default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site, aasm_state: :initial_enrollment_closed)
      }

      context "inital employer on transmission day => 26th of month" do



        it "should transmit only employer_A " do
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,26))
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,26))
        end

        it "should not transmit employer_B, C, D, E, F, G, H" do
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,26))
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,26))
        end
      end

      context "transmission day for late inital employer => 27th of month" do

        before :each do
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,27))
          employer_C.approve_initial_enrollment_eligibility!
          benefit_app = employer_C.benefit_applications.where(aasm_state: :enrollment_eligible).first
          benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,26) )
        end

        it "should transmit only employer_C " do
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,27))
        end

        it "should not transmit employer_A, B, D, E, F, G, H" do
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,27))
        end
      end

      context "transmission day for late inital employer => 28th of month" do

        before :each do
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,28))
          employer_D.approve_initial_enrollment_eligibility!
          benefit_app = employer_D.benefit_applications.where(aasm_state: :enrollment_eligible).first
          benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,27) )
        end


        it "should transmit only employer_D " do
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,28))
        end

        it "should not transmit employer_A, B, C, E, F, G, H" do
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,28))
        end
      end

      context "transmission day for late inital employer => 29th of month" do

        before :each do
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,29))
          employer_E.approve_initial_enrollment_eligibility!
          benefit_app = employer_E.benefit_applications.where(aasm_state: :enrollment_eligible).first
          benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,28) )
        end


        it "should transmit only employer_E " do
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,29))
        end

        it "should not transmit employer_A, B, C, D, F, G, H" do
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,29))
        end
      end

      context "transmission day for late inital employer => 30th of month" do

        before :each do
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,30))
          employer_F.approve_initial_enrollment_eligibility!
          benefit_app = employer_F.benefit_applications.where(aasm_state: :enrollment_eligible).first
          benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,29) )
        end


        it "should transmit only employer_F " do
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,30))
        end

        it "should not transmit employer_A, B, C, D, E, G, H" do
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,30))
        end
      end

      context "transmission day for late inital employer => 31th of month" do

        before :each do
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,31))
          employer_G.approve_initial_enrollment_eligibility!
          benefit_app = employer_G.benefit_applications.where(aasm_state: :enrollment_eligible).first
          benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,30) )
        end


        it "should transmit only employer_G " do
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,31))
        end

        it "should not transmit employer_A, B, C, D, E, F, H" do
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,31))
        end
      end

      context "transmission day for late inital employer => 01th of month" do

        before :each do
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,4,1))
          employer_H.approve_initial_enrollment_eligibility!
          benefit_app = employer_H.benefit_applications.where(aasm_state: :enrollment_eligible).first
          benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,31) )
        end


        it "should transmit only employer_H " do
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,4,1))
        end

        it "should not transmit employer_A, B, C, D, E, F, G" do
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_initial_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_initial_application_eligible'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,4,1))
        end
      end
    end

  describe "renewal employer monthly transmission for the month MARCH:
       - employer A renewing benefit application :
         - published renewal benefit application
         - Open Enrollment Closed
         - benefit application moved to enrollment_eligible state

       - employer B renewing benefit application:
         - published renewal benefit application
         - Open Enrollment Closed
         - benefit application moved to enrollment_ineligible state

       - employer C renewing benefit application :
         - published renewal benefit application
         - Open Enrollment Closed
         - benefit application moved to enrollment_eligible state i.e on 27th

       - employer D renewing benefit application :
         - published renewal benefit application
         - Open Enrollment Closed
         - benefit application moved to enrollment_eligible state i.e on 29th

       - employer E renewing benefit application :
         - published renewal benefit application
         - Open Enrollment Closed
         - benefit application moved to enrollment_eligible state i.e on 28th

       - employer F renewing benefit application :
         - published renewal benefit application
         - Open Enrollment Closed
         - benefit application moved to enrollment_eligible state i.e on 29th

       - employer G renewing benefit application :
         - published renewal benefit application
         - Open Enrollment Closed
         - benefit application moved to enrollment_eligible state i.e on 30th

       - employer H renewing benefit application :
         - employer switched carrier in renewal application
         - published renewal benefit application
         - Open Enrollment Closed
         - benefit application moved to enrollment_eligible state i.e on 31th
    ", dbclean: :after_each do


    let(:initial_application_state)       { :active }
    let!(:this_year)                       { TimeKeeper.date_of_record.year }
    let(:april_effective_date)            { Date.new(this_year,4,1) }

    let!(:employer_A)  { build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                :with_renewal_benefit_application, initial_application_state: :active,
                                renewal_application_state: :enrollment_eligible,
                                default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                                aasm_state: :active)}

    let!(:employer_B)  { build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                               :with_renewal_benefit_application, initial_application_state: :active,
                               renewal_application_state: :enrollment_ineligible,
                               default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                               aasm_state: :active)}

    let!(:employer_C)  { build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                               :with_renewal_benefit_application, initial_application_state: :active,
                               renewal_application_state: :enrollment_closed,
                               default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                               aasm_state: :active)}

    let!(:employer_D)  { build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                               :with_renewal_benefit_application, initial_application_state: :active,
                               renewal_application_state: :enrollment_closed,
                               default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                               aasm_state: :active)}

    let!(:employer_E)  { build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                               :with_renewal_benefit_application, initial_application_state: :active,
                               renewal_application_state: :enrollment_closed,
                               default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                               aasm_state: :active)}

    let!(:employer_F)  { build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                               :with_renewal_benefit_application, initial_application_state: :active,
                               renewal_application_state: :enrollment_closed,
                               default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                               aasm_state: :active)}
    let!(:employer_G)  { build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                               :with_renewal_benefit_application, initial_application_state: :active,
                               renewal_application_state: :enrollment_closed,
                               default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                               aasm_state: :active)}
    let!(:employer_H)  { build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                               :with_renewal_benefit_application, initial_application_state: :active,
                               renewal_application_state: :enrollment_closed,
                               default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                               aasm_state: :active)}

    context "renewal employer on transmission day => 26th of month" do

      before :each do
        active_benefit_app = employer_A.benefit_applications.where(aasm_state: :active).first
        employer_A.benefit_applications.where(aasm_state: :enrollment_eligible).first.update_attributes(predecessor_id: active_benefit_app.id)
      end

      it "should transmit only employer_A " do
        allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,26))
        expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,26))
      end

      it "should not transmit employer_B, C, D, E, F, G, H" do
        allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,26))
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,26))
      end
    end

    context "transmission day for late renewal employer => 27th of month" do

      before :each do
        allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,27))
        benefit_app = employer_C.benefit_applications.where(aasm_state: :enrollment_closed).first
        benefit_app.approve_enrollment_eligiblity!
        active_benefit_app = employer_A.benefit_applications.where(aasm_state: :active).first
        employer_A.benefit_applications.where(aasm_state: :enrollment_eligible).first.update_attributes(predecessor_id: active_benefit_app.id)
        benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,26) )
      end

      it "should transmit only employer_C " do
        expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,27))
      end

      it "should not transmit employer_A, B, D, E, F, G, H" do
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,27))
      end
    end

    context "transmission day for late renewal employer => 28th of month" do

      before :each do
        allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,28))
        benefit_app = employer_D.benefit_applications.where(aasm_state: :enrollment_closed).first
        benefit_app.approve_enrollment_eligiblity!
        active_benefit_app = employer_A.benefit_applications.where(aasm_state: :active).first
        employer_A.benefit_applications.where(aasm_state: :enrollment_eligible).first.update_attributes(predecessor_id: active_benefit_app.id)
        benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,27) )
      end


      it "should transmit only employer_D " do
        expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,28))
      end

      it "should not transmit employer_A, B, C, E, F, G, H" do
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,28))
      end
    end

    context "transmission day for late renewal employer => 29th of month" do

      before :each do
        allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,29))
        benefit_app = employer_E.benefit_applications.where(aasm_state: :enrollment_closed).first
        benefit_app.approve_enrollment_eligiblity!
        active_benefit_app = employer_A.benefit_applications.where(aasm_state: :active).first
        employer_A.benefit_applications.where(aasm_state: :enrollment_eligible).first.update_attributes(predecessor_id: active_benefit_app.id)
        benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,28) )
      end


      it "should transmit only employer_E " do
        expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,29))
      end

      it "should not transmit employer_A, B, C, D, F, G, H" do
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,29))
      end
    end

    context "transmission day for late renewal employer => 30th of month" do

      before :each do
        allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,30))
        benefit_app = employer_F.benefit_applications.where(aasm_state: :enrollment_closed).first
        benefit_app.approve_enrollment_eligiblity!
        active_benefit_app = employer_A.benefit_applications.where(aasm_state: :active).first
        employer_A.benefit_applications.where(aasm_state: :enrollment_eligible).first.update_attributes(predecessor_id: active_benefit_app.id)
        benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,29) )
      end


      it "should transmit only employer_F " do
        expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,30))
      end

      it "should not transmit employer_A, B, C, D, E, G, H" do
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,30))
      end
    end

    context "transmission day for late renewal employer => 31th of month" do

      before :each do
        allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,3,31))
        benefit_app = employer_G.benefit_applications.where(aasm_state: :enrollment_closed).first
        benefit_app.approve_enrollment_eligiblity!
        active_benefit_app = employer_A.benefit_applications.where(aasm_state: :active).first
        employer_A.benefit_applications.where(aasm_state: :enrollment_eligible).first.update_attributes(predecessor_id: active_benefit_app.id)
        benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,30) )
      end


      it "should transmit only employer_G " do
        expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,31))
      end

      it "should not transmit employer_A, B, C, D, E, F, H" do
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,3,31))
      end
    end

    context "transmission day for late renewal employer => 01th of month" do

      before :each do
        allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,4,1))
        benefit_app = employer_H.benefit_applications.where(aasm_state: :enrollment_closed).first
        benefit_app.approve_enrollment_eligiblity!
        active_benefit_app = employer_A.benefit_applications.where(aasm_state: :active).first
        employer_A.benefit_applications.where(aasm_state: :enrollment_eligible).first.update_attributes(predecessor_id: active_benefit_app.id)
        benefit_app.workflow_state_transitions.where(to_state: :enrollment_eligible).first.update_attributes(transition_at: Date.new(TimeKeeper.date_of_record.year,3,31) )
      end

      it "should transmit only employer_H " do
        allow_any_instance_of( BenefitSponsors::BenefitSponsorships::BenefitSponsorship).to receive(:is_renewal_carrier_drop?).and_return(true)
        expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_carrier_dropped", {employer_id: employer_H.profile.hbx_id, event_name: 'benefit_coverage_renewal_carrier_dropped'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,4,1))
      end

      it "should not transmit employer_A, B, C, D, E, F, G" do
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_C.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_D.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_E.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_F.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_application_eligible", {employer_id: employer_G.profile.hbx_id, event_name: 'benefit_coverage_renewal_application_eligible'})
        BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,4,1))
      end
    end
  end
  end
end





