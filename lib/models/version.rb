class Version < ActiveRecord::Base
  set_table_name :versions

  named_scope :most_recent, :order => "version DESC", :limit => 1
  
  validates_presence_of :target
  validates_presence_of :version
  validates_numericality_of :version, :greater_than => 0
  validates_uniqueness_of :version, :scope => [:target_type, :target_id]
  
  belongs_to :target, :polymorphic => true
  belongs_to :author, :polymorphic => true
  
  has_many :attribute_changes, :dependent => :destroy
  
  # Sets the +version+ number (simply the next available number determined via SQL).
  before_validation_on_create do |model|
    if model.target
      model.version = model.target.new_record? ? 1 : (model.target.versions.maximum(:version) || 0) + 1
    end
  end
  
  # Will apply a set of +changes+ (retrieved via Rails' dirty changes) and
  # delete +AttributeChanges+ where necessary. If all changes are destroyed
  # by this the +Version+ will destroy itself.
  def merge!(changes)
    raise "cannot merge! a new_record" if new_record?
    
    Version.transaction do
      changes.each do |attribute, diff|
        change = attribute_changes.find_or_initialize_by_attribute(attribute.to_s) do |a|
          a.attribute_type = target.column_for_attribute(attribute.to_s).type.to_s
        end
        change.update_by_diff(diff) ? change.save! : change.destroy
      end
      self.destroy if attribute_changes(:reload).empty?
    end
  end
end
