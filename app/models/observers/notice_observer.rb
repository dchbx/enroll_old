module Observers
  class NoticeObserver < Observer
    
    def plan_year_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if PlanYear::REGISTERED_EVENTS.include?(new_model_event.event_key)
        plan_year = new_model_event.klass_instance
        
        if new_model_event.event_key == :renewal_application_denied
          errors = plan_year.enrollment_errors

          if(errors.include?(:eligible_to_enroll_count) || errors.include?(:non_business_owner_enrollment_count))
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_employer_ineligibility_notice")

            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "employee_renewal_employer_ineligibility_notice")
              end
            end
          end
        end
        
        if new_model_event.event_key == :renewal_application_submitted
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_published")
        end

        if new_model_event.event_key == :renewal_application_created
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_created")
        end

        if new_model_event.event_key == :ineligible_renewal_application_submitted
          
          if plan_year.application_eligibility_warnings.include?(:primary_office_location)
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "employer_renewal_eligibility_denial_notice")
            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "termination_of_employers_health_coverage")
              end
            end
          end
        end
      end

      if PlanYear::DATA_CHANGE_EVENTS.include?(new_model_event.event_key)
      end
    end

    def employer_profile_update; end

    def hbx_enrollment_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent) 

      if  HbxEnrollment::REGISTERED_EVENTS.include?(new_model_event.event_key)
        hbx_enrollment = new_model_event.klass_instance

        if new_model_event.event_key == :application_coverage_selected
          if enrollment.is_shop? && (enrollment.enrollment_kind == "special_enrollment" || enrollment.census_employee.new_hire_enrollment_period.present?)
            if enrollment.census_employee.new_hire_enrollment_period.last >= TimeKeeper.date_of_record || enrollment.special_enrollment_period.present?
              trigger_notice(recipient: enrollment.census_employee.employee_role, event_object: hbx_enrollment, notice_event: "employee_plan_selection_confirmation_sep_new_hire")
            end
          end
        end
      end
    end

    def census_employee_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent) 

      if  CensusEmployee::REGISTERED_EVENTS.include?(new_model_event.event_key)  
        census_employee = new_model_event.klass_instance

        if new_model_event.event_key == :renewal_oe_employee_not_enrolled
          trigger_notice(recipient: census_employee.employee_role, event_object: new_model_event.options[:event_object], notice_event: "renewal_open_enrollment_employee_unenrolled")
        end

        if new_model_event.event_key == :passive_renewals_failed
          trigger_notice(recipient: census_employee.employee_role, event_object: new_model_event.options[:event_object], notice_event: "passive_renewals_failed")
        end

        if new_model_event.event_key == :renewal_oe_employee_auto_renewal
          trigger_notice(recipient: census_employee.employee_role, event_object: new_model_event.options[:event_object], notice_event: "renewal_oe_employee_auto_renewal")
        end

      end
    end
  end
end