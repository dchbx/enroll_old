require File.join(Rails.root, "app", "data_migrations", "define_permissions")

#All hbx_roles can view families, employers, broker_agencies, brokers and general agencies
#The convention for a privilege group 'x' is  'modify_x', or view 'view_x'

namespace :permissions do
  desc 'define the permissions'
  DefinePermissions.define_task :initial_hbx => :environment
end
namespace :permissions do
  desc 'build test roles'
  DefinePermissions.define_task :build_test_roles => :environment
end
namespace :permissions do
  desc 'hbx admin can update ssn'
  DefinePermissions.define_task :hbx_admin_can_update_ssn => :environment
end

namespace :permissions do
  desc 'hbx admin can complete resident application'
  DefinePermissions.define_task :hbx_admin_can_complete_resident_application => :environment
end

namespace :permissions do
  desc 'hbx admin can add sep'
  DefinePermissions.define_task :hbx_admin_can_add_sep => :environment
end

namespace :permissions do
  desc 'hbx admin can add pdc'
  DefinePermissions.define_task :hbx_admin_can_add_pdc => :environment
end

namespace :permissions do
  desc 'hbx admin can view username and email'
  DefinePermissions.define_task :hbx_admin_can_view_username_and_email => :environment
end

namespace :permissions do
  desc 'hbx admin can view application types of consumer'
  DefinePermissions.define_task :hbx_admin_can_view_application_types => :environment
end

namespace :permissions do
  desc 'hbx admin and csr view personal information page of consumer'
  DefinePermissions.define_task :hbx_admin_csr_view_personal_info_page => :environment
end

namespace :permissions do
  desc 'hbx admin and csr view new consumer application link tab'
  DefinePermissions.define_task :hbx_admin_can_access_new_consumer_application_sub_tab => :environment
end

namespace :permissions do
  desc 'hbx admin and csr view identity verification link tab'
  DefinePermissions.define_task :hbx_admin_can_access_identity_verification_sub_tab => :environment
end

namespace :permissions do
  desc 'hbx admin can view outstanding verification link tab'
  DefinePermissions.define_task :hbx_admin_can_access_outstanding_verification_sub_tab => :environment
end

namespace :permissions do
  desc 'hbx admin can transition family members'
  DefinePermissions.define_task :hbx_admin_can_transition_family_members => :environment
end

namespace :permissions do
  desc 'hbx admin can access accept reject identity documents'
  DefinePermissions.define_task :hbx_admin_can_access_accept_reject_identity_documents => :environment
end

namespace :permissions do
  desc 'hbx admin and all csr access accept reject paper application documents'
  DefinePermissions.define_task :hbx_admin_can_access_accept_reject_paper_application_documents => :environment
end

namespace :permissions do
  desc 'hbx admin can delete identity and paper application documents'
  DefinePermissions.define_task :hbx_admin_can_delete_identity_application_documents => :environment
end

namespace :permissions do
  desc 'hbx_admin_can_access_pay_now'
  DefinePermissions.define_task :hbx_admin_can_access_pay_now => :environment
end

namespace :permissions do
  desc 'hbx admin can access user account tab'
  DefinePermissions.define_task :hbx_admin_can_access_user_account_tab => :environment
end

#rake permissions:initial_hbx
#rake permissions:migrate_hbx
#rake permissions:hbx_admin_can_update_ssn
#rake permissions:hbx_admin_can_complete_resident_application
#rake permissions:hbx_admin_can_view_application_types
#rake permissions:hbx_admin_csr_view_personal_info_page
#rake permissions:hbx_admin_can_access_new_consumer_application_sub_tab
#rake permissions:hbx_admin_can_access_identity_verification_sub_tab
#rake permissions:hbx_admin_can_access_outstanding_verification_sub_tab
#rake permissions:hbx_admin_can_transition_family_members
#rake permissions:hbx_admin_can_add_pdc
#rake permissions:hbx_admin_can_access_accept_reject_identity_documents
#rake permissions:hbx_admin_can_access_accept_reject_paper_application_documents
#rake permissions:hbx_admin_can_delete_identity_application_documents
#rake permissions:hbx_admin_can_access_pay_now
#rake permissions:hbx_admin_can_access_user_account_tab
