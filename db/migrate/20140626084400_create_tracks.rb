class CreateTracks < ActiveRecord::Migration
  def change
    create_table :tracks do |t|
      t.integer :number
      t.string :title
      t.integer :minutes
      t.integer :seconds
      t.references :release

      t.timestamps
    end
  end
end
