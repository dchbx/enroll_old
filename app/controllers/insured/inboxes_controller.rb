class Insured::InboxesController < InboxesController

  def find_inbox_provider
    @inbox_provider = Family.find(params["family_id"])
    @inbox_provider_name = @inbox_provider.primary_applicant.person.full_name
  end

  def successful_save_path
    exchanges_hbx_profiles_root_path
  end

end