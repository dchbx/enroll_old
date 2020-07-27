# frozen_string_literal: true
require 'dry/monads'
require 'dry/monads/do'
module Operations
  module Shop
    class DependentAgeOff
      include Config::SiteConcern
      send(:include, Dry::Monads[:result, :do])

      def call(new_date:)
        yield can_process_event(new_date)
        shop_logger = yield initialize_logger("shop")
        query_criteria = yield shop_query_criteria
        process_shop_dep_age_off(query_criteria, shop_logger, new_date)
      end

      private

      def can_process_event(new_date)
        if new_date != TimeKeeper.date_of_record.end_of_year && ::EnrollRegistry[:aca_shop_dependent_age_off].settings(:period).item == :annual
          Failure('Cannot process the request, because shop dependent_age_off is not set for end of every month')
        else
          Success('')
        end
      end

      def initialize_logger(market_kind)
        logger_file = Logger.new("#{Rails.root}/log/dependent_age_off_#{market_kind}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
        Success(logger_file)
      end

      def shop_query_criteria
        Success(HbxEnrollment.enrolled.shop_market.all_with_multiple_enrollment_members)
      end

      def process_shop_dep_age_off(enrollments, shop_logger, new_date)
        cut_off_age = EnrollRegistry[:aca_shop_dependent_age_off].settings(:cut_off_age).item
        enrollments.no_timeout.inject([]) do |_result, enrollment|
          next if enrollment.employer_profile&.is_fehb?
          primary_person = enrollment.family.primary_person
          enr_members = enrollment.hbx_enrollment_members
          covered_family_members = enr_members.map(&:family_member)
          covered_members = covered_family_members.map(&:person)
          covered_members_ids = covered_members.flat_map(&:_id)
          relations = fetch_relation_objects(primary_person, covered_members_ids)
          next if relations.blank?

          aged_off_dependent_people = fetch_aged_off_people(relations, new_date, cut_off_age)
          next if aged_off_dependent_people.empty?
          dep_age_off_people_ids = aged_off_dependent_people.pluck(:id)
          age_off_family_members = covered_family_members.select{|fm| dep_age_off_people_ids.include?(fm.person_id)}.pluck(:id)
          age_off_enr_member = enr_members.select{|hem| age_off_family_members.include?(hem.applicant_id)}
          eligible_dependents = enr_members - age_off_enr_member
          effective_date = new_date + 1.day
          terminate_and_reinstate_enrollment(enrollment, effective_date, eligible_dependents)
          rescue Exception => e
          shop_logger.info "Unable to terminated enrollment #{enrollment.hbx_id} for #{e.message}"
        end
        Success('Successfully dropped dependents for SHOP market')
      end

      def fetch_aged_off_people(relations, new_date, cut_off_age)
        relations.select{|dep| (dep.relative.age_on(new_date)) >= cut_off_age}.flat_map(&:relative).select{|p| p.age_off_excluded == false}
      end

      def fetch_relation_objects(primary_person, covered_members_ids)
        primary_person.person_relationships.where(kind: "child").select{ |rel| (covered_members_ids.include? rel.relative_id)}
      end

      def terminate_and_reinstate_enrollment(enrollment, effective_date, eligible_dependents)
        reinstate_enrollment = Enrollments::Replicator::Reinstatement.new(enrollment, effective_date, nil, eligible_dependents).build
        reinstate_enrollment.save!
        if reinstate_enrollment.may_reinstate_coverage?
          reinstate_enrollment.reinstate_coverage!
          reinstate_enrollment.begin_coverage! if reinstate_enrollment.may_begin_coverage?
          reinstate_enrollment.begin_coverage! if reinstate_enrollment.may_begin_coverage? && self.effective_on <= TimeKeeper.date_of_record
        end
      end
    end
  end
end