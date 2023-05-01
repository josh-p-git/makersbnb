# frozen_string_literal: true

class Property < ActiveRecord::Base
  belongs_to :user
  has_many :bookings
  has_many :availabilitys
end
