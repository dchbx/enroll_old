require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class ShopEnrollmentReport < MongoidMigrationTask
  def migrate
    if ENV['purchase_date_start'].blank? && ENV['purchase_date_end'].blank?
       # Purchase dates are from 30 days to todays date
      purchase_date_start = (Time.now - 30.days).beginning_of_day
      purchase_date_end = Time.now.end_of_day
    else
      purchase_date_start = Time.strptime(ENV['purchase_date_start'],'%m/%d/%Y').beginning_of_day
      purchase_date_end = Time.strptime(ENV['purchase_date_end'],'%m/%d/%Y').end_of_day
    end
    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")

    qs = Queries::PolicyAggregationPipeline.new
    qs.filter_to_shopping_completed
    qs.eliminate_family_duplicates
    qs.add({ "$match" => {"policy_purchased_at" => {"$gte" => purchase_date_start, "$lte" => purchase_date_end}}})
    glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip) if File.exist?("all_glue_policies.txt")
    enrollment_ids = []

    qs.evaluate.each do |r|
      enrollment_ids << r['hbx_id']
    end

    enrollment_ids_final = []
    enrollment_ids.each{|id| (enrollment_ids_final << id)}
    writing_on_csv(enrollment_ids_final, glue_list)
    puts "Shop Enrollment Report Generated" unless Rails.env.test?
  end

  def writing_on_csv(enrollment_ids_final, glue_list)
    shop_headers = ['Employer ID', 'Employer FEIN', 'Employer Name', 'Plan Year Start', 'Plan Year State', 'Employer State',
                    'Enrollment GroupID', 'Purchase Date', 'Coverage Start', 'Coverage End', 'Coverage Kind', 'Enrollment State', 
                    'Subscriber HBXID', 'Subscriber First Name','Subscriber Last Name', 'HIOS ID', 'Premium Subtotal', 
                    'ER Contribution', 'Applied APTC Amount', 'Total Responsible Amount', 'Family Size', 'Enrollment Reason', 'In Glue']
    file_name = "#{Rails.root}/hbx_report/shop_enrollment_report.csv"

    rating_area_cache = get_rating_areas
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << shop_headers
      enrollment_ids_final.each_slice(400) do |en_slice|
        en_org_map = get_employer_profiles_for(en_slice)
        en_pers_map = get_people_for(en_slice)
        f_member_person_map = get_family_member_map(en_slice)
        enrollment_map = Hash.new
        product_map = get_products_for(en_slice)
        HbxEnrollment.where("hbx_id" => {"$in" => en_slice.to_a}).each do |en|
          enrollment_map[en.hbx_id] = en
        end
        rel_map = get_relationship_map(enrollment_map.values,  f_member_person_map)
        sb_map = get_sponsored_benefit_map(en_slice)
        en_slice.each do |id|
          begin
            hbx_enrollment = enrollment_map[id]
            next unless hbx_enrollment.is_shop?
            sponsored_benefit = sb_map[hbx_enrollment.sponsored_benefit_id]
            hbx_enrollment.sponsored_benefit = sponsored_benefit
            hbx_enrollment.sponsored_benefit_package = sponsored_benefit.benefit_package
            hbx_enrollment.benefit_sponsorship = sponsored_benefit.benefit_package.benefit_application.benefit_sponsorship
            employer_profile =  if en_org_map.has_key?(id)
                                   en_org_map[id]
                                else
                                  hbx_enrollment.employer_profile
                                end
            enrollment_reason = enrollment_kind(hbx_enrollment)
            product = product_map[id]
            calculator = Enrollments::RandomAccessSponsoredEnrollmentCalculator.new(
              hbx_enrollment,
              f_member_person_map,
              rel_map,
              sb_map,
              rating_area_cache
            ).groups_for_products([product]).first.group_enrollment
            plan_year = sponsored_benefit.benefit_package.benefit_application
            plan_year_start = plan_year.start_on.to_s
            if en_pers_map.has_key?(id)
              subscriber = en_pers_map[id]
              subscriber_hbx_id = subscriber.hbx_id
              first_name = subscriber.first_name
              last_name = subscriber.last_name
            end
            in_glue = glue_list.include?(id) if glue_list.present?
            csv << [
              employer_profile.hbx_id, employer_profile.fein, employer_profile.legal_name,
              plan_year_start, plan_year.aasm_state, plan_year.benefit_sponsorship.aasm_state,
              hbx_enrollment.hbx_id, hbx_enrollment.created_at, hbx_enrollment.effective_on,
              hbx_enrollment.terminated_on, hbx_enrollment.coverage_kind, hbx_enrollment.aasm_state,
              subscriber_hbx_id,first_name,last_name,
              product.hios_id,
              calculator.total_premium, calculator.total_employer_contribution, hbx_enrollment.applied_aptc_amount, calculator.total_employee_cost,
              hbx_enrollment.hbx_enrollment_members.size,
              enrollment_reason,
              in_glue]
          rescue StandardError => e
            @logger = Logger.new("#{Rails.root}/log/shop_enrollment_report_error.log")
            (@logger.error { "Could not add the hbx_enrollment's information on to the CSV for eg_id:#{id}, subscriber_hbx_id:#{subscriber_hbx_id}, #{e.inspect}" }) unless Rails.env.test?
          end
        end
      end
    end
  end

  def get_rating_areas
    ra_map = Hash.new
    BenefitMarkets::Locations::RatingArea.all.each do |ra|
      ra_map[ra.id] = ra
    end
    ra_map
  end

  def get_products_for(enrollment_hbx_ids)
    en_p_id_map = Hash.new
    product_map = Hash.new
    product_ids = Array.new
    HbxEnrollment.collection.aggregate([
      {"$match" => {"hbx_id" => {"$in" => enrollment_hbx_ids.to_a}}},
      {"$project" => {"product_id" => 1, "hbx_id" => 1}}
    ]).each do |rec|
      en_p_id_map[rec["hbx_id"]] = rec["product_id"]
      product_ids << rec["product_id"]
    end
    product_id_map = Hash.new
    BenefitMarkets::Products::Product.where(
      "_id" => {"$in" => product_ids}
    ).each do |product|
      product_id_map[product.id] = product
    end
    en_p_id_map.each_pair do |k, v|
      if product_id_map.has_key?(v)
        product_map[k] = product_id_map[v]
      end
    end
    product_map
  end

  def get_people_for(enrollment_hbx_ids)
    p_en_id_map = Hash.new
    en_pers_map = Hash.new
    person_ids = Array.new
    HbxEnrollment.collection.aggregate([
      {"$match" => {"hbx_id" => {"$in" => enrollment_hbx_ids.to_a}}},
      {"$project" => {"hbx_id" => 1, "family_id" => 1}},
      {"$lookup" => {
        "from" => "families",
        "localField" => "family_id",
        "foreignField" => "_id",
        "as" => "family"
      }},
      {"$unwind" => "$family"},
      {"$project" => {"hbx_id" => 1, "family_id" => 1, "family.family_members" => 1}},
      {"$unwind" => "$family.family_members"},
      {"$match" => {"family.family_members.is_primary_applicant" => true}},
      {"$project" => {"hbx_id" => 1, "person_id" => "$family.family_members.person_id"}}
    ]).each do |rec|
      p_en_id_map[rec["hbx_id"]] = rec["person_id"]
      person_ids << rec["person_id"]
    end
    pers_id_map = Hash.new
    Person.where(
      "_id" => {"$in" => person_ids}  
    ).each do |person|
      pers_id_map[person.id] = person
    end
    p_en_id_map.each_pair do |k, v|
      if pers_id_map.has_key?(v)
        en_pers_map[k] = pers_id_map[v]
      end
    end
    en_pers_map
  end

  def get_sponsored_benefit_map(enrollment_hbx_ids)
    product_map = Hash.new
    product_ids = Array.new
    bsc_ids = Array.new
    HbxEnrollment.collection.aggregate([
      {"$match" => {"hbx_id" => {"$in" => enrollment_hbx_ids.to_a}}},
      {"$project" => {"sponsored_benefit_id" => 1, "hbx_id" => 1}}
    ]).each do |rec|
      product_ids << rec["sponsored_benefit_id"]
    end
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(
      "benefit_applications.benefit_packages.sponsored_benefits._id" => {"$in" => product_ids.compact}  
    ).each do |bs|
      bs.benefit_applications.each do |ba|
        bsc_ids << ba.benefit_sponsor_catalog_id
        ba.benefit_packages.flat_map(&:sponsored_benefits).each do |sb|
          product_map[sb.id] = sb
        end
      end
    end
    bsc_id_map = Hash.new
    BenefitMarkets::BenefitSponsorCatalog.where(
      "_id" => {"$in" => bsc_ids.compact}
    ).without("product_packages.products").each do |bsc|
      bsc_id_map[bsc.id] = bsc
    end
    product_map.values.each do |sb|
      ba = sb.benefit_package.benefit_application
      bsc_id = ba.benefit_sponsor_catalog_id
      if bsc_id_map.has_key?(bsc_id)
        ba.benefit_sponsor_catalog = bsc_id_map[bsc_id]
        bsc_id_map[bsc_id].benefit_application = ba
      end
    end
    product_map
  end

  def get_family_member_map(enrollment_hbx_ids)
    f_member_pid_map = Hash.new
    f_member_pers_map = Hash.new
    person_ids = Array.new
    HbxEnrollment.collection.aggregate([
      {"$match" => {"hbx_id" => {"$in" => enrollment_hbx_ids.to_a}}},
      {"$project" => {"hbx_id" => 1, "family_id" => 1}},
      {"$lookup" => {
        "from" => "families",
        "localField" => "family_id",
        "foreignField" => "_id",
        "as" => "family"
      }},
      {"$unwind" => "$family"},
      {"$project" => {"hbx_id" => 1, "family_id" => 1, "family.family_members" => 1}},
      {"$unwind" => "$family.family_members"},
      {"$project" => {"person_id" => "$family.family_members.person_id", "family_member_id" => "$family.family_members._id"}}
    ]).each do |rec|
      f_member_pid_map[rec["family_member_id"]] = rec["person_id"]
      person_ids << rec["person_id"]
    end
    pers_id_map = Hash.new
    Person.where(
      "_id" => {"$in" => person_ids}
    ).each do |person|
      pers_id_map[person.id] = person
    end
    f_member_pid_map.each_pair do |k, v|
      if pers_id_map.has_key?(v)
        f_member_pers_map[k] = pers_id_map[v]
      end
    end
    f_member_pers_map
  end

  def get_relationship_map(enrollments, family_member_map)
    rel_mapping = Hash.new
    enrollments.each do |en|
      subscriber = en.hbx_enrollment_members.detect(&:is_subscriber?)
      if subscriber
        if family_member_map.has_key?(subscriber.applicant_id)
          sub_person = family_member_map[subscriber.applicant_id]
          en.hbx_enrollment_members.each do |hem|
            if !hem.is_subscriber?
              if family_member_map.has_key?(hem.applicant_id)
                hem_person = family_member_map[hem.applicant_id]
                rel_mapping[[hem.applicant_id, subscriber.applicant_id]] = sub_person.find_relationship_with(hem_person)
              end
            end
          end
        end
      end
    end
    rel_mapping
  end

  def get_employer_profiles_for(enrollment_hbx_ids)
    bs_id_map = Hash.new
    org_ids = Array.new
    en_org_map = Hash.new
    HbxEnrollment.collection.aggregate([
      {"$match" => {"hbx_id" => {"$in" => enrollment_hbx_ids.to_a}}},
      {"$project" => {"hbx_id" => 1, "benefit_sponsorship_id" => 1}},
      {"$lookup" => {
        "from" => "benefit_sponsors_benefit_sponsorships_benefit_sponsorships",
        "localField" => "benefit_sponsorship_id",
        "foreignField" => "_id",
        "as" => "benefit_sponsorship"
      }},
      {"$unwind" => "$benefit_sponsorship"},
      {"$project" => {"hbx_id" => 1, "organization_id" => "$benefit_sponsorship.organization_id"}}
    ]).each do |rec|
      bs_id_map[rec["hbx_id"]] = rec["organization_id"]
      org_ids << rec["organization_id"]
    end
    org_id_map = Hash.new
    BenefitSponsors::Organizations::Organization.where(
      "_id" => {"$in" => org_ids}  
    ).each do |org|
      org_id_map[org.id] = org
    end
    bs_id_map.each_pair do |k, v|
      if org_id_map.has_key?(v)
        en_org_map[k] = org_id_map[v]
      end
    end
    en_org_map
  end

  def enrollment_kind(hbx_enrollment)
    case hbx_enrollment.enrollment_kind
    when "special_enrollment"
      hbx_enrollment.special_enrollment_period.qualifying_life_event_kind.reason
    when "open_enrollment"
      hbx_enrollment.eligibility_event_kind
    end
  end
end