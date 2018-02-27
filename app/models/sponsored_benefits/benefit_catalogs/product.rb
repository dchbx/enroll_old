module SponsoredBenefits
  module BenefitCatalogs
    class Product
      include Mongoid::Document
      include Mongoid::Timestamps

      # Product grouping attribute hierarchy that may be used to filter query and display results
      FILTERS = {}

      field :hbx_id,              type: Integer
      field :purchase_period,     type: Range  # => jan 1 - dec 31, 2018
      field :benefit_market_kind, type: Symbol
      field :product_kind,        type: Symbol

      field :title,               type: String
      field :abbrev,              type: String
      field :description,         type: String

      field :benefit_catalog_id,  type: BSON::ObjectId
      field :issuer_profile_id,   type: BSON::ObjectId

      field :renewal_plan_id,     type: BSON::ObjectId

      field :age_range, type: Range, default:  0..120  # move this to member policy? 

      # 1-5 stars crowd sourced rating (polymorphic)
      field :crowd_rating,  type: String
      field :tags,          type: Array, default: []


      embeds_many :rating_areas,          class_name: "SponsoredBenefits::BenefitProducts::RatingArea"
      embeds_many :benefit_product_rates, class_name: "SponsoredBenefits::BenefitProducts::BenefitProductRate"

      belongs_to :issuer, class_name: "SponsoredBenefits::Organizations::Organization"


      scope :find_by_benefit_catalog, ->(benefit_catalog){ where(benefit_catalog_id: BSON::ObjectId.from_string(benefit_catalog._id)) }
      scope :find_by_issuer_profile,  ->(benefit_catalog){ where(issuer_profile_id: BSON::ObjectId.from_string(issuer_profile._id)) }
      scope :contains_purchase_date,  ->(date){ where( :"purchase_period.min".gte => date,
                                                      :"purchase_period.max".lte => date)
                                                    }

      index({ :hbx_id => 1 } )
      index({ :renewal_plan_id => 1 } )
      index({ :benefit_catalog_id => 1 } )
      index({ :issuer_profile_id => 1 } )
      index({ :benefit_market_kind => 1, :"purchase_period.min" => 1, :"purchase_period.max" => 1, :product_kind => 1 }, { name: "purchase_period" })
      index({ :benefit_market_kind => 1, :issuer_profile_id => 1, :product_kind => 1, :"purchase_period.min" => 1, :"purchase_period.max" => 1, }, { name: "purchase_period" })

      validates :kind,
        inclusion: { in: SponsoredBenefits::BENEFIT_MARKET_KINDS, message: "%{value} is not a valid benefit market kind" },
        allow_nil:    false

      validates :product_kind,
        inclusion: { in: SponsoredBenefits::PRODUCT_KINDS, message: "%{value} is not a valid product kind" },
        allow_nil:    false


      def issuer

      end

      def price_range
      end


      def issuer_profile
        SponsoredBenefits::Organizations::IssuerProfile.find(issuer_profile_id)
      end

      def sponsor_eligibility_policies
      end

      def member_eligibility_policies
      end

      # builders: sponsor (rating area, sic), effective_date

      ## Dates

      ## Benefit Product rate period - BenefitProduct
      # DC & MA SHOP Health: Q1, Q2, Q3, Q4
      # DC Dental: annual
      # GIC Medicare: Jan-June, July-Dec
      # DC & MA IVL: annual



      # Effective dates during which sponsor may purchase this product at this price
      ## DC SHOP Health   - annual product changes & quarterly rate changes
      ## CCA SHOP Health  - annual product changes & quarterly rate changes
      ## DC IVL Health    - annual product & rate changes
      ## Medicare         - annual product & semiannual rate changes

      field :product_purchase_period, type: Range
      has_many :rate_tables


    end
  end
end
