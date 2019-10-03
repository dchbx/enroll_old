# This rake task is to
# RAILS_ENV=production bundle exec rake migrations:update_carrier_name abbrev=xyz name="carrier_name"

require File.join(Rails.root, "app", "data_migrations", "update_carrier_name")
namespace :migrations do
  desc "update carrier name"
  UpdateCarrierName.define_task :update_carrier_name => :environment
end
