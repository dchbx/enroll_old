require File.join(Rails.root, "app", "data_migrations", "remove_invalid_benefit_group_assignments")
# This rake task is to remove the invalid benefit group assignments for the EE's
# RAILS_ENV=production bundle exec rake migrations:remove_invalid_benefit_group_assignments fein=521247182
namespace :migrations do
  desc "changing conversion ER's plan year status to migration expired state"
  RemoveInvalidBenefitGroupAssignments.define_task :remove_invalid_benefit_group_assignments => :environment
end
