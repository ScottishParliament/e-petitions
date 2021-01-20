class ChangeDefaultsForScottishParliament < ActiveRecord::Migration[5.2]
  def change
    change_column_default :sites,
                          :title_en,
                          from: %[Petition the Senedd],
                          to:   %[Petition the Scottish Parliament]

    change_column_default :sites,
                          :url_en,
                          from: %[https://petitions.senedd.wales],
                          to:   %[https://petitions.parliament.scot]

    change_column_default :sites,
                          :email_from_en,
                          from: %["Petitions: Welsh Parliament" <no-reply@petition.senedd.wales>"],
                          to:   %["Petitions: Scottish Parliament" <no-reply@petitions.parliament.scot>"]

    change_column_default :sites, :moderate_url,
                          from: %[https://moderate.petitions.senedd.wales],
                          to:   %[https://moderate.petitions.parliament.scot]

    change_column_default :sites, :feedback_email,
                          from: %["Petitions: Welsh Parliament" <petitionscommittee@senedd.wales>],
                          to:   %["Petitions: Scottish Parliament" <petitionscommittee@parliament.scot>]

    change_column_default :sites,
                          :title_cy,
                          from: %[Deisebu'r Senedd],
                          to:   %[Athchuinge do Phàrlamaid na h-Alba]

    change_column_default :sites,
                          :url_cy,
                          from: %[https://deisebau.senedd.cymru],
                          to:   %[https://athchuingean.parlamaid-alba.scot]

    change_column_default :sites,
                          :email_from_cy,
                          from: %["Deisebau: Senedd" <dim-ateb@deisebau.senedd.cymru>"],
                          to:   %["Athchuingean: Pàrlamaid na h-Alba" <gun-fhreagairt@athchuingean.parlamaid-alba.scot>]
  end
end
