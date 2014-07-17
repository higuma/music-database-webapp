class CreateReleases < ActiveRecord::Migration
  def change
    create_table :releases do |t|
      t.string :title
      t.integer :year
      t.references :artist

      t.timestamps
    end
  end
end
