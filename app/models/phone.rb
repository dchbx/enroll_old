class Phone
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable

  embedded_in :person
  embedded_in :office_location
  embedded_in :census_member, class_name: "CensusMember"

  KINDS = ["home", "work", "mobile", "main", "fax"]
  OFFICE_KINDS = ["phone main"]

  field :kind, type: String
  field :country_code, type: String, default: ""
  field :area_code, type: String, default: ""
  field :number, type: String, default: ""
  field :extension, type: String, default: ""
  field :primary, type: Boolean
  field :full_phone_number, type: String, default: ""

  track_history :on => [:fields],
                :scope => :person,
                :modifier_field => :modifier,
                :modifier_field_optional => true,
                :version_field => :tracking_version,
                :track_create  => true,    # track document creation, default is false
                :track_update  => true,    # track document updates, default is true
                :track_destroy => true

  before_validation :save_phone_components

  before_save :set_full_phone_number

  validates :area_code,
    numericality: true,
    length: { minimum: 3, maximum: 3, message: "%{value} is not a valid area code" },
    allow_blank: false

  validates :number,
    numericality: true,
    length: { minimum: 7, maximum: 7, message: "%{value} is not a valid phone number" },
    allow_blank: false

  validate :validate_phone_kind

  def blank?
    [:full_phone_number, :area_code, :number, :extension].all? do |attr|
      self.send(attr).blank?
    end
  end

  def save_phone_components
    phone_number = filter_non_numeric(self.full_phone_number).to_s
    if !phone_number.blank?
      length=phone_number.length
      if length>10
        self.area_code = phone_number[0,3]
        self.number = phone_number[3,7]
        self.extension = phone_number[10,length-10]
      elsif length==10
        self.area_code = phone_number[0,3]
        self.number = phone_number[3,7]
        self.extension = ""
      end
    end
  end

  def full_phone_number=(new_full_phone_number)
   super filter_non_numeric(new_full_phone_number)
   save_phone_components
  end

  def area_code=(new_area_code)
   super filter_non_numeric(new_area_code)
  end

  def number=(new_number)
   super filter_non_numeric(new_number)
  end

  def extension=(new_extension)
   super filter_non_numeric(new_extension)
  end

  def to_s
    full_number = (self.area_code + self.number).to_i
    if self.extension.present?
      full_number.to_s(:phone, area_code: true, extension: self.extension)
    else
      full_number.to_s(:phone, area_code: true)
    end
  end

  def set_full_phone_number
    self.full_phone_number = to_s
  end

  def is_only_individual_person_phone?
    # broker role phones will still be listed under the person record
    # need to check if its attached to the broker role first too
    # use & in case no broker_Role present
    person_is_phone_parent = self._parent.class == Person
    phone_number_is_not_broker_role_number = if _parent&.broker_role&.phone.respond_to?(:full_phone_number)
                                 _parent&.broker_role&.phone.full_phone_number != full_phone_number
                               elsif _parent.broker_role
                                  # Needs to compensate because the broker_agency_profile
                                  # wont be a phone instance that responds to full_phone_number
                                  # but a string like "(202) 111-1111 x 3"
                                  _parent.broker_role.phone.scan(/\d/).join.exclude?(full_phone_number)
                                else # No broker role present
                                  true
                               end
    # all? will return false if any value is nil or false
    [person_is_phone_parent, phone_number_is_not_broker_role_number].all?
  end
  
  # Needs to compensate because the broker_agency_profile wont be a phone instance that responds to full_phone_number, but a string like
  # "(202) 111-1111 x 3"
  # def phone
  #  parent.phones.where(kind: "phone main").first || broker_agency_profile.phone || parent.phones.where(kind: "work").first rescue ""
  # end

  private

  def validate_phone_kind
    # "phone main" is invalid EDI for individual person phones
    # broker role phones will stil
    if self.is_only_individual_person_phone?
      errors.add(:kind, "#{kind} is not a valid phone type") unless kind.in?(KINDS)
    else # is an office
      errors.add(:kind, "#{kind} is not a valid phone type") unless kind.in?(KINDS + OFFICE_KINDS)
    end
  end
  
  def filter_non_numeric(str)
    str.present? ? str.to_s.gsub(/\D/,'') : ""
  end
end
