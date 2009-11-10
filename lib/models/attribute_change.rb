class AttributeChange < ActiveRecord::Base
  set_table_name :attribute_changes
  
  validates_presence_of :version
  validates_presence_of :attribute_type
  validates_inclusion_of :attribute_type, :in => %w( string text integer float decimal datetime timestamp time date binary boolean )
  validates_uniqueness_of :attribute, :scope => :version_id
  
  belongs_to :version
  
  # Populates/updates the +AttributeChange+ model. Will only update the
  # +new+ field if the model was already persisted.
  #
  # Returns false if +old+ equals +new+. This is used as in indicator for
  # +version.merge!+ that this +AttributeChange+ should be destroyed.
  def update_by_diff(diff)
    self.old = diff[0] if new_record?
    self.new = diff[1]
    old != new
  end
  
  def old=(old_value)
    self.send "old_#{attribute_type}=", old_value
  end
  
  def new=(new_value)
    self.send "new_#{attribute_type}=", new_value
  end
  
  def old # :nodoc:
    self.send "old_#{attribute_type}"
  end
  
  def new # :nodoc:
    self.send "new_#{attribute_type}"
  end
end
