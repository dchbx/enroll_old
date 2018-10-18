require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateSpecialEnrollmentPeriod < MongoidMigrationTask
  def migrate
    SpecialEnrollmentPeriod.find(ENV['sep_id']).update_attributes(ENV["attrs"])
  end
end
