# frozen_string_literal: true

module BenefitMarkets
  module Entities
    module ContributionModels
      class ContributionModel < Dry::Struct
        transform_keys(&:to_sym)

        attribute :title,                         Types::Strict::String
        attribute :key,                           Types::String.optional.meta(omittable: true)
        attribute :sponsor_contribution_kind,     Types::Strict::String
        attribute :contribution_calculator_kind,  Types::Strict::String
        attribute :many_simultaneous_contribution_units,  Types::Strict::Bool
        attribute :product_multiplicities, Types::Strict::Array
        attribute :contribution_units, Types::Array.of(ContributionModels::ContributionUnit)
        attribute :member_relationships, Types::Array.of(ContributionModels::MemberRelationship)

      end
    end
  end
end