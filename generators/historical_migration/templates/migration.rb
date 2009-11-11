class HistoricalMigration < ActiveRecord::Migration
  def self.up
    create_table :model_saves do |t|
      t.integer :version
      t.string  :type
      t.text    :cause
      
      t.integer :target_id
      t.string  :target_type
      
      t.integer :author_id
      t.string  :author_type

      t.timestamps
    end
  
    create_table :attribute_updates do |t|
      t.integer :parent_id
      
      t.string :attribute
      t.string :attribute_type
      
      # new/old columns for each supported column-type
<%- %w( string text integer float decimal datetime timestamp time date binary boolean ).each do |w| -%>
      <%= "t.#{w} :new_#{w}, :null => true" %>
      <%= "t.#{w} :old_#{w}, :null => true" %>
<%- end -%>
    end
  end
  
  def self.down
    drop_table :model_saves
    drop_table :attribute_updates
  end
end