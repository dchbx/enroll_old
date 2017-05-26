FactoryGirl.define do

  factory :consumer_role, class: EnrollCore::ConsumerRole do
    association :person
    sequence(:ssn) { |n| "7"+SecureRandom.random_number.to_s[2..8][0..-((Math.log(n+1,10))+1)]+"#{n+1}"}
    dob "01/01/1980"
    gender 'male'
    is_state_resident 'yes'
    citizen_status 'us_citizen'
    is_incarcerated 'yes'
    is_applicant 'yes'
    vlp_documents {[FactoryGirl.build(:vlp_document)]}
    bookmark_url nil
  end

  factory(:consumer_role_person, class: EnrollCore::Person) do
    first_name { Forgery(:name).first_name }
    last_name { Forgery(:name).first_name }
    gender { Forgery(:personal).gender }
    sequence(:ssn, 222222222)
    dob Date.new(1980, 1, 1)
  end


  factory(:consumer_role_object, class: EnrollCore::ConsumerRole) do
    is_applicant true
    person { FactoryGirl.create(:consumer_role_person) }
  end

end
