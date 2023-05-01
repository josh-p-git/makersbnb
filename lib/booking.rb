# frozen_string_literal: true

class Booking < ActiveRecord::Base
  belongs_to :user
  belongs_to :property
end
