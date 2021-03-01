class RenameAbmsLinkColumn < ActiveRecord::Migration[6.1]
  def change
    rename_column :petitions, :abms_link_en, :scot_parl_link_en
    rename_column :petitions, :abms_link_gd, :scot_parl_link_gd
  end
end
