module DocumentsVerificationStatus
  def verification_type_status(type, member, admin=false)
    applicant_in_context = @f_member.applicant_for_verification if @f_member
    consumer = member.consumer_role
    if (consumer.vlp_authority == "curam" && consumer.fully_verified?)
      admin ? "curam" : "External source"
    else
      case type
        when 'Social Security Number'
          if consumer.ssn_verified?
            "verified"
          elsif consumer.has_docs_for_type?(type) && !consumer.ssn_rejected
            "review"
          elsif consumer.ssa_pending?
            "processing"
          else
            "outstanding"
          end
        when 'American Indian Status'
          if consumer.native_verified?
            "verified"
          elsif consumer.has_docs_for_type?(type) && !consumer.native_rejected
            "review"
          else
            "outstanding"
          end
        when 'DC Residency'
          if consumer.residency_verified?
            consumer.residency_attested? ? "attested" : "verified"
          elsif consumer.has_docs_for_type?(type) && !consumer.residency_rejected
            "review"
          elsif consumer.residency_pending?
            "processing"
          else
            "outstanding"
          end
        when 'Income'
          if applicant_in_context.present?
            if applicant_in_context.assisted_income_verified?
              "verified"
            elsif applicant_in_context.has_faa_docs_for_type?(type)
              "in review"
            else
              "outstanding"
            end
          end
        when 'MEC'
          if applicant_in_context.present?
            if applicant_in_context.assisted_mec_verified?
              "verified"
            elsif applicant_in_context.has_faa_docs_for_type?(type)
              "in review"
            else
              "outstanding"
            end
          end
        else
          if consumer.lawful_presence_verified?
            "verified"
          elsif consumer.has_docs_for_type?(type) && !consumer.lawful_presence_rejected
            "review"
          elsif consumer.citizenship_immigration_processing?
            "processing"
          else
            "outstanding"
          end
      end
    end
  end
end