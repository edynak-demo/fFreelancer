class Pricing < ApplicationRecord
  belongs_to :service
  enum pricing_type: [:basic, :standard, :premium]
end
