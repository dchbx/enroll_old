require File.join(Rails.root, "app", "data_migrations", "updating_person_ssn")

#this rake task is used to update person ssn
#RAILS_ENV=production rake migrations:updating_person_ssn hbx_id_1="19756344" person_ssn="321312312"

namespace :migrations do
  desc 'exchange the ssns between two accounts'
  UpdatingPersonSsn.define_task :updating_person_ssn => :environment
end

