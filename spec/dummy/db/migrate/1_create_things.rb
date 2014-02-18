Sequel.migration do

  change do
    create_table :things do
      primary_key :id
    end
  end

end
