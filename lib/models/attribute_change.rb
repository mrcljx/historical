class AttributeChange < ActiveRecord::Base
  set_table_name :attribute_changes
  
  validates_presence_of :version
  validates_uniqueness_of :attribute, :scope => :version_id
  
  belongs_to :version
  
  # Populates/updates the +AttributeChange+ model. Will only update the
  # +new+ field if the model was already persisted.
  #
  # Returns false if +old+ equals +new+. This is used as in indicator for
  # +version.merge!+ that this +AttributeChange+ should be destroyed.
  def update_by_diff(diff)
    if new_record?
      self.old_value = diff[0]
      self.old_class = diff[0].class.name
    end
    
    self.new_value = diff[1]
    self.new_class = diff[1].class.name
    
    old != new
  end
  
  def old # :nodoc:
    old_value	   
  end
  
  def new # :nodoc:
    new_value	   
  end
end
