class AddCollectSignaturesToPetitions < ActiveRecord::Migration[6.1]
  def change
    add_column :petitions, :collect_signatures, :boolean, default: false
  end
end
