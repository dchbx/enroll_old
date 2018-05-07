## Product premium costs for a specified time period
# Effective periods:
#   DC & MA SHOP Health: Q1, Q2, Q3, Q4
#   DC Dental: annual
#   GIC Medicare: Jan-June, July-Dec
#   DC & MA IVL: annual

module BenefitMarkets
  class Products::PremiumTable
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :product, class_name: "Products::Product"

    field       :effective_period,  type: Range


    belongs_to  :rating_area,
                class_name: "BenefitMarkets::Locations::RatingArea"

    embeds_many :premium_tuples,
                class_name: "BenefitMarkets::Products::PremiumTuple", cascade_callbacks: true

    validates_presence_of :effective_period #, :rating_area
    validates_presence_of :premium_tuples, :allow_blank => false

  end
end
