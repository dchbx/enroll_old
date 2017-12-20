require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::ProfilesController < ApplicationController
    include Acapi::Notifiers
    include Config::AcaConcern
    include DataTablesAdapter
    include Config::BrokerAgencyHelper

    before_action :find_broker_agency_profile, only: [:employers, :new]

    def employers
      ::Effective::Datatables::BrokerAgencyEmployerDatatable.profile_id = @broker_agency_profile._id
      @datatable = ::Effective::Datatables::BrokerAgencyEmployerDatatable.new
    end

    def new
      @organization = ::Forms::EmployerProfile.new
      get_sic_codes
    end

    def create

    end

  private  
    def find_broker_agency_profile
      @broker_agency_profile = ::BrokerAgencyProfile.find(params[:profile_id])
      #authorize @broker_agency_profile, :access_to_broker_agency_profile?
    end

    def get_sic_codes
      @grouped_options = {}
      ::SicCode.all.group_by(&:industry_group_label).each do |industry_group_label, sic_codes|
        @grouped_options[industry_group_label] = sic_codes.collect{|sc| ["#{sc.sic_label} - #{sc.sic_code}", sc.sic_code]}
      end
    end
  end
end
