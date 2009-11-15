class ModelSave < ActiveRecord::Base
  set_table_name :model_saves
  
  default_scope :order => "model_saves.target_type ASC, model_saves.target_id ASC, model_saves.version ASC"
  
  validates_presence_of :type
  validates_presence_of :target
  validates_presence_of :version
  validates_numericality_of :version, :only_integer => true
  validates_uniqueness_of :version, :scope => [:target_type, :target_id]
  
  belongs_to :target, :polymorphic => true
  belongs_to :author, :polymorphic => true
  
  has_many :attribute_updates, :foreign_key => :parent_id, :dependent => :destroy
  
  alias attr_updates attribute_updates
end

class ModelUpdate < ModelSave
  validates_numericality_of :version, :greater_than => 0
  
  # Sets the +version+ number (simply the next available number determined via SQL).
  before_validation_on_create do |model|
    model.version = model.target.latest_version if model.target
  end
  
  # Will apply a set of +changes+ (retrieved via Rails' dirty changes) and
  # delete +AttributeChanges+ where necessary. If all changes are destroyed
  # by this the +Update+ will destroy itself.
  def merge!(changes, author = nil)
    raise "cannot merge! a new_record" if new_record?
    
    ModelUpdate.transaction do
      changes.each do |attribute, diff|
        change = attribute_updates.find_or_initialize_by_attribute(attribute.to_s) do |a|
          a.attribute_type = target.column_for_attribute(attribute.to_s).type.to_s
        end
        equal_attributes = change.update_by_diff(diff)
        equal_attributes ? change.save! : change.destroy
      end
      
      if attribute_updates(:reload).empty?
        destroy 
      elsif author and self.author != author
        self.author = author
        save!
      end
    end
  end
  
  def modified_attributes
    @modified_attributes ||= attribute_updates.collect{ |u| u.attribute.to_sym }.to_set
  end
  
  def modified_attributes_without_associations
    returning modified_attributes.clone do |result|
      outgoing_association_attributes.each do |attr, assoc|
        result.delete(attr) if result.include? attr
      end
    end
  end
  
  def modified_attributes_and_associations
    returning modified_attributes.clone do |result|
      outgoing_association_attributes.each do |attr, assoc|
        if result.include? attr
          result.delete(attr)
          result << assoc.name.to_sym
        end
      end
    end
  end
  
  alias :modifications :modified_attributes_and_associations
  
  protected
  
  def model_class
    target_type.constantize
  end
  
  def outgoing_association_attributes
    @outgoing_association_attributes ||= returning({}) do |result|
      outgoing_associations.each do |assoc|
        result[assoc.primary_key_name.to_sym] = assoc
        if assoc.options[:polymorphic]
          col = assoc.options[:foreign_type]
          result[col.to_sym] = assoc
        end
      end
    end
  end
  
  def outgoing_associations
    model_class.reflect_on_all_associations(:belongs_to)
  end
  
  # resolves associations
  def method_missing_with_changes(method, *args)
    method_name = method.to_s
    if method_name =~ /^(old|new)_([[:alnum:]_]+)$/
      action, name = $1, $2
      
      # try to find a column
      if column = target.column_for_attribute(name)
        change = attribute_updates.find_by_attribute(column.name)
        raise "#{name} didn't change" unless change
        change.send action
      
      # find ActiveRecord::Reflection::MacroReflection
      elsif assoc = model_class.reflect_on_association(name.to_sym)
        raise "only supports belongs_to" unless assoc.belongs_to?
        
        if assoc.options[:polymorphic]
          id = self.send("#{action}_#{assoc.primary_key_name}")
          type = self.send("#{action}_#{assoc.options[:foreign_type]}")
          type ? type.constantize.find(id) : nil
        else
          assoc.klass.find(self.send("#{action}_#{assoc.primary_key_name}"))
        end
        
      # failed
      else
        method_missing_without_changes(method, *args)  
      end
    else
      method_missing_without_changes(method, *args)
    end
  end
  
  alias_method_chain :method_missing, :changes
end

class ModelCreation < ModelSave
  validates_numericality_of :version, :equal_to => 0
  validates_uniqueness_of :target_id, :scope => [:target_type]
  
  # Sets the +version+ number (simply the next available number determined via SQL).
  before_validation_on_create do |model|
    model.version = 0
  end
end
