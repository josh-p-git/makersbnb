class CreateAvailability < ActiveRecord::Migration[7.0]
  def change
    create_table :avails do |t|
      t.belongs_to :property, index: true, foreign_key: true
      t.date :first_available
      t.date :last_available
    end
  end
end
