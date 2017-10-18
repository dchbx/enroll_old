module Observers
  class NoticeObserver < Observer

    PLANYEAR_NOTICE_EVENTS = [
      :renewal_application_created,
      :renewal_group_notice,
      :initial_application_submitted,
      :renewal_application_submitted,
      :renewal_application_autosubmitted,
      :ineligible_initial_application_submitted,
      :ineligible_renewal_application_submitted,
      :open_enrollment_began,
      :open_enrollment_ended,
      :application_denied,
      :renewal_application_denied
    ]
  
    def plan_year_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if PLANYEAR_NOTICE_EVENTS.include?(new_model_event.event_key)
        plan_year = new_model_event.klass_instance

        if new_model_event.event_key == :intial_application_submitted
        end

        if new_model_event.event_key == :renewal_application_denied
         errors = plan_year.enrollment_errors

          if(errors.include?(:eligible_to_enroll_count) || errors.include?(:non_business_owner_enrollment_count))
            trigger_notice(plan_year.employer_profile, "renewal_employer_ineligibility_notice")
          end
        end 

        if new_model_event.event_key == :renewal_application_submitted
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_published")
        end

        if new_model_event.event_key == :renewal_group_notice
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_group_notice")
        end

        if new_model_event.event_key == :ineligible_initial_application_submitted
          eligibility_warnings = plan_year.application_eligibility_warnings

          # if (eligibility_warnings.include?(:primary_office_location) || eligibility_warnings.include?(:fte_count))
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "initial_employer_denial")
          # end
        end

        if new_model_event.event_key == :ineligible_renewal_application_submitted && plan_year.application_eligibility_warnings.include?(:primary_office_location)
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "employer_renewal_eligibility_denial_notice")
          self.employer_profile.census_employees.non_terminated.each do |ce|
            trigger_notice(ce.id.to_s, "termination_of_employers_health_coverage")
          end
        end

      end
    end

    def employer_profile_update; end
    def hbx_enrollment_update; end
    def census_employee_update; end
  end
end