# frozen_string_literal: true

class User < ActiveRecord::Base
  has_secure_password
  validates_uniqueness_of :email
  has_many :bookings
  has_many :properties
end
