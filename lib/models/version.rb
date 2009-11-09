class Version < ActiveRecord::Base
  set_table_name :versions

  named_scope :most_recent, :order => "created_at DESC"
  
  validates_presence_of :target
  validates_presence_of :version
  validates_numericality_of :version, :greater_than => 0
  validates_uniqueness_of :version, :scope => [:target_type, :target_id]
  
  belongs_to :target, :polymorphic => true
  belongs_to :author, :polymorphic => true
  
  has_many :attribute_changes, :dependent => :destroy
  
  before_validation_on_create do |model|
    if model.target
      model.version = model.target.new_record? ? 1 : (model.target.versions.maximum(:version) || 0) + 1
    end
  end
  
  def merge!(changes)
    raise "cannot merge! a new_record" if new_record?
    
    changes.each do |attribute, diff|
      change = attribute_changes.find_or_initialize_by_attribute(attribute.to_s)
      if change.update_by_diff(diff)
        change.save!
      else
        change.destroy
      end
    end
    
    self.destroy if attribute_changes(:reload).empty?
  end
end