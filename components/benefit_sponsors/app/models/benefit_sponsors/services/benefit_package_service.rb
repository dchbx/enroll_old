module BenefitSponsors
  module Services
    class BenefitPackageService

      attr_reader :benefit_package_factory, :benefit_application

      def initialize(factory_kind = BenefitSponsors::BenefitPackages::BenefitPackageFactory)
        @benefit_package_factory = factory_kind
      end

      # load defaults from models
      def load_default_form_params(form)
        application  = find_benefit_application(form)
        form.id = application.benefit_packages.new.id
      end

      def load_form_metadata(form)
        application  = find_benefit_application(form)
        form.catalog = BenefitSponsors::BenefitApplications::BenefitSponsorCatalogDecorator.new(application.benefit_sponsor_catalog)
      end

      def load_form_params_from_resource(form)
        application  = find_benefit_application(form)
        benefit_package = find_model_by_id(form.id)
        attributes_to_form_params(benefit_package, form)
      end

      def disable_benefit_package(form)
        benefit_application = find_benefit_application(form)
        benefit_package = find_model_by_id(form.id)
        if benefit_package.disable_benefit_package
          return [true, benefit_package]
        else
          map_errors_for(benefit_package, onto: form)
          return [false, nil]
        end
      end

      def save(form)
        benefit_application = find_benefit_application(form)
        model_attributes = form_params_to_attributes(form)
        benefit_package = benefit_package_factory.call(benefit_application, model_attributes)
        store(form, benefit_package)
      end

      def update(form)
        benefit_application = find_benefit_application(form)
        benefit_package = find_model_by_id(form.id)
        model_attributes = form_params_to_attributes(form)
        benefit_package.assign_attributes(model_attributes)
        store(form, benefit_package)
      end

      # TODO: Test this query for benefit applications cca/dc
      # TODO: Change it back to find once find method on BenefitApplication is fixed.
      def find_model_by_id(id)
        @benefit_application.benefit_packages.find(id)
      end

      # TODO: Change it back to find once find method on BenefitSponsorship is fixed.
      def find_benefit_application(form)
        return @benefit_application if defined? @benefit_application
        @benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.find(form.benefit_application_id)
      end

      def store(form, benefit_package)
        valid_according_to_factory = benefit_package_factory.validate(benefit_application)
        if valid_according_to_factory
        else
          map_errors_for(benefit_package, onto: form)
          return [false, nil]
        end
        save_successful = benefit_package.save
        unless save_successful
          map_errors_for(benefit_package, onto: form)
          return [false, nil]
        end
        [true, benefit_package]
      end

      def map_errors_for(benefit_package, onto:)
        benefit_package.errors.each do |att, err|
          onto.errors.add(map_model_error_attribute(att), err)
        end
      end

      # We can cheat here because our form and our model are so
      # close together - normally this will be more complex
      def map_model_error_attribute(model_attribute_name)
        model_attribute_name
      end

      private

      def attributes_to_form_params(benefit_package, form)
        form.attributes = {
          title: benefit_package.title,
          description: benefit_package.description,
          probation_period_kind: benefit_package.probation_period_kind,
          sponsored_benefits: sponsored_benefits_attributes_to_form_params(benefit_package)
        }
        form.attributes
      end

      def sponsored_benefits_attributes_to_form_params(benefit_package)
        benefit_package.sponsored_benefits.inject([]) do |sponsored_benefits, sponsored_benefit|
          sponsored_benefits << Forms::SponsoredBenefitForm.new({
            product_option_choice: sponsored_benefit.product_option_choice,
            product_package_kind: sponsored_benefit.product_package_kind,
            reference_plan_id: sponsored_benefit.reference_product.id,
            sponsor_contribution: sponsored_contribution_attributes_to_form_params(sponsored_benefit)
          })
        end
      end

      def sponsored_contribution_attributes_to_form_params(sponsored_benefit)
        contribution_levels = sponsored_benefit.sponsor_contribution.contribution_levels.inject([]) do |contribution_levels, contribution_level|
          contribution_levels << Forms::ContributionLevelForm.new({
            display_name: contribution_level.display_name,
            contribution_factor: contribution_level.contribution_factor,
            is_offered: contribution_level.is_offered
          })
        end
        Forms::SponsorContributionForm.new({contribution_levels: contribution_levels})
      end

      def form_params_to_attributes(form)
        attributes = {
          title: form.title,
          description: form.description,
          probation_period_kind: form.probation_period_kind
        }
        attributes[:sponsored_benefits] = sponsored_benefits_attributes(form)
        attributes
      end

      def sponsored_benefits_attributes(form)
        form.sponsored_benefits.inject([]) do |sponsored_benefits, sponsored_benefit|
          sponsored_benefits << {
            kind: sponsored_benefit.kind,
            product_package_kind: sponsored_benefit.product_package_kind,
            product_option_choice: sponsored_benefit.product_option_choice,
            reference_plan_id: sponsored_benefit.reference_plan_id,
            sponsor_contribution: sponsored_contribution_attributes(sponsored_benefit)
          }
        end
      end

      def sponsored_contribution_attributes(sponsored_benefit)
        contribution = sponsored_benefit.sponsor_contribution
        contribution_levels = contribution.contribution_levels.inject([]) do |contribution_levels, contribution_level|
          contribution_levels << {
            display_name: contribution_level.display_name,
            contribution_factor: contribution_level.contribution_factor,
            is_offered: contribution_level.is_offered
          }
        end

        { contribution_levels: contribution_levels}
      end
    end
  end
end