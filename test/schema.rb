ActiveRecord::Schema.define(:version => 0) do
  create_table :posts, :force => true do |t|
    t.string :topic
    t.text :content
    t.integer :author_id
    t.integer :rating
    t.timestamps
  end
  create_table :people, :force => true do |t|
    t.string :name
    t.string :email
    t.timestamps
  end
  create_table :accounts, :force => true do |t|
    t.string :login
    t.string :password
    t.timestamps
  end
  create_table :versions, :force => true do |t|
    t.integer :target_id
    t.string :target_type
    t.integer :author_id
    t.string :author_type
    t.integer :version
    t.text :cause
    t.timestamps
  end
  create_table :attribute_changes, :force => true do |t|
    t.integer :version_id
    t.string :attribute
    t.string :old_class
    t.text :old_value
    t.string :new_class
    t.text :new_value
  end
end