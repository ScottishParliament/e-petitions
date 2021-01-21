class ChangeColumnNamesForScottishParliament < ActiveRecord::Migration[5.2]
  def change
    change_table :constituencies do |t|
      t.rename :name_cy, :name_gd
    end

    change_table :debate_outcomes do |t|
      t.rename :debate_pack_url_cy, :debate_pack_url_gd
      t.rename :overview_cy, :overview_gd
      t.rename :transcript_url_cy, :transcript_url_gd
      t.rename :video_url_cy, :video_url_gd
    end

    change_table :members do |t|
      t.rename :name_cy, :name_gd
      t.rename :party_cy, :party_gd
    end

    change_table :petition_emails do |t|
      t.rename :body_cy, :body_gd
      t.rename :subject_cy, :subject_gd
    end

    change_table :petitions do |t|
      t.rename :action_cy, :action_gd
      t.rename :additional_details_cy, :additional_details_gd
      t.rename :abms_link_cy, :abms_link_gd
      t.rename :background_cy, :background_gd

      t.rename_index :index_petitions_on_action_cy, :index_petitions_on_action_gd
      t.rename_index :index_petitions_on_background_cy, :index_petitions_on_background_gd
      t.rename_index :index_petitions_on_additional_details_cy, :index_petitions_on_additional_details_gd
    end

    change_table :regions do |t|
      t.rename :name_cy, :name_gd
    end

    change_table :rejection_reasons do |t|
      t.rename :description_cy, :description_gd
    end

    change_table :sites do |t|
      t.rename :title_cy, :title_gd
      t.rename :url_cy, :url_gd
      t.rename :email_from_cy, :email_from_gd
    end

    change_table :topics do |t|
      t.rename :code_cy, :code_gd
      t.rename :name_cy, :name_gd
    end

    change_table :rejections do |t|
      t.rename :details_cy, :details_gd
    end
  end
end
