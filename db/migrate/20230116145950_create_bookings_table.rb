class CreateBookingsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :bookings do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :property, index: true, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.boolean :approved
      t.boolean :responded
    end
  end
end
