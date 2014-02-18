Sequel.migration do
  
  change do
    create_table :items do
      primary_key :id
    end
  end

end
