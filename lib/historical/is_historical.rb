module Historical
  class AuthorRequired < ActiveRecord::RecordInvalid
    def initialize(record); super(record); end  
  end

  module IsHistorical
    VALID_HISTORICAL_OPTIONS = [:timestamps, :except, :only, :merge, :require_author]
    VALID_HISTORICAL_MERGE_OPTIONS = [:if_time_difference_is_less_than]
    TIMESTAMP_ATTRIBUTES = %w{created_at updated_at}

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      # Decides wether the +model+ with the specified changes can be merged. This
      # is based on whether there exists a +Update+ which the new changes could
      # be merged with and whether the time threshold allows merging.
      def can_merge?(model, changes, author = nil)
        last = model.updates.last
        return false unless last
        
        if self.historical_merge_options[:if_time_difference_is_less_than]
          last.created_at >= self.historical_merge_options[:if_time_difference_is_less_than].ago
        else
          raise "unknown merge settings"
        end
      end
      
      def validate_historical_options(options) # :nodoc:
        options.assert_valid_keys(VALID_HISTORICAL_OPTIONS)
      end
      
      def validate_historical_merge_options(options) # :nodoc:
        return unless options
        options.assert_valid_keys(VALID_HISTORICAL_MERGE_OPTIONS)
      end
      
      delegate :as_historical_author, :historical_author, :to => Historical::ActionControllerExtension
    
      # == Configuration options
      #
      # * <tt>except</tt> - excludes the specified colums from versioning
      # * <tt>only</tt> - only includes the specified columns for versioning
      # * <tt>timestamps</tt> - whether or not to include created_at and updated_at for versioning (default: false)
      # * <tt>merge</tt> - options for update-merging to avoid clutter (default: false)
      def is_historical(options = {})
        raise "is_historical was already called" if @historical_enabled
        @historical_enabled = true
        
        options = {:timestamps => false, :only => false, :except => false, :require_author => false}.merge(options)
        validate_historical_options(options)
        validate_historical_merge_options(options[:merge])
        
        send :include, InstanceMethods
        
        cattr_accessor :historical_merge_options
        self.historical_merge_options = options[:merge]
        
        has_many :saves, :class_name => "ModelSave", :as => :target, :dependent => :destroy
        has_many :updates, :class_name => "ModelUpdate", :as => :target
        
        has_many :attribute_updates, :through => :updates
        
        only = options[:only]
        only = Array.wrap(only).collect{ |x| x.to_s } if only
        
        except = options[:except]
        except = Array.wrap(except).collect{ |x| x.to_s } if except
        
        require_author = options[:require_author]
        
        raise "You can't use :only and :except at the same time" if only and except
        
        after_create do |model|
          ModelUpdate.transaction do
            author = model.historical_author
            raise Historical::AuthorRequired.new(model) if require_author and not author
            model.saves << ModelCreation.create!(:author => author, :target => model)
          end
          
          model
        end
        
        after_update do |model|
          next unless model.changed? and model.changes
          
          changes = model.changes.reject do |k,v|
            if only
              !only.include? k
            elsif except and except.include? k
              true
            elsif !options[:timestamps]
              TIMESTAMP_ATTRIBUTES.include? k
            else
              false
            end
          end
          
          next if changes.empty?
          
          author = model.historical_author
          raise Historical::AuthorRequired.new(model) if require_author and not author
          
          ModelUpdate.transaction do
            if self.historical_merge_options and can_merge?(model, changes, author)
              model.updates.last.merge!(changes, author)
            else
              update = model.updates.create!(:author => author)
              changes.collect do |attribute, diff|
                update.attribute_updates.create! do |change|
                  column = model.column_for_attribute(attribute.to_s)
                  raise "no such column: #{attribute}" unless column
                  change.parent = update
                  change.attribute = attribute.to_s
                  change.attribute_type = column.type.to_s
                  change.update_by_diff(diff)
                end
              end
            end
          end
          
          model
        end
      end
    end

    module InstanceMethods
      def as_version(version_number)
        version_number = version_number.to_i
        version_number = version + version_number if version_number < 0
        raise ActiveRecord::RecordNotFound, "version would be before creation (version: #{version_number})" if version_number <= 0
        
        fake = self.class.find(id)
        
        return fake if latest_version == version_number
        raise ActiveRecord::RecordNotFound, "version would be in the future (version: #{version_number}, latest: #{latest_version})" if version_number > latest_version
        
        self.class.columns.each do |col|
          # no need to join manually, because it's a has_many :through relation
          change = attribute_updates.first(:conditions => ["model_saves.version >= ? AND attribute_updates.attribute = ?", version_number, col.name],
                                          :order => "model_saves.version ASC")
          fake[col.name] = change.old if change
        end
        
        fake.instance_variable_set :@version, version_number
        fake.instance_variable_set :@reverted, true
        
        fake.readonly!
        fake
      end
      
      def updates(reload = false)
        saves(reload).without_creations
      end
      
      def creation(reload = false)
        saves(reload).only_creations.first
      end

      def reverted?; !!@reverted; end
      
      def latest_version(reload = false)
        if new_record?
          0
        else
          (saves(reload).maximum(:version) || 0) + 1
        end
      end
      
      def historical_author
        self.class.historical_author
      end
      
      def version
        if reverted?
          @version
        else
          latest_version
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Historical::IsHistorical
