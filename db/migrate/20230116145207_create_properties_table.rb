class CreatePropertiesTable < ActiveRecord::Migration[7.0]
  def change
    create_table :properties do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.string :title
      t.string :address
      t.text :description
      t.integer :daily_rate
    end
  end
end
