require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "A historical model" do
  class User < ActiveRecord::Base
    set_table_name "users"
  end
  
  class Message < ActiveRecord::Base
    extend Historical::ActiveRecord
    is_historical
  end
  
  context "when loading model from database without history" do
    before :each do
      @old_autospawn_value = Historical.autospawn_creation
      Historical.boot!
      @msg = Message.find(1)
      @msg.history.destroy
    end
    
    after :each do
      Historical.autospawn_creation = @old_autospawn_value
    end
    
    it "should call the creation-generator" do
      o = Object.new
      o.stub!(:created_at=).once.with(@msg.created_at)
      o.stub!(:save!).once
      
      @msg.should_receive(:spawn_version).once.with(:create).and_return(o)
      @msg.history
    end
    
    it "should auto-generate a creation" do
      @msg.history.version_index.should == 0
      @msg.history.creation.should_not be_nil
    end
    
    it "should not auto-generate creation if auto-generation is disabled" do
      Historical.autospawn_creation = false
      @msg.history.creation.should be_nil
    end
    
    it "should have the original timestamps" do
      @msg.history.creation.tap do |e|
        e.created_at.should == @msg.created_at
      end
    end
  end
  
  context "when created" do
    it "should persist" do
      msg = Message.new(:title => "Hello")
      msg.save.should be_true
    end
    
    it "should create a creation-diff" do
      msg = Message.create(:title => "Hello")
      
      msg.history.tap do |h|
        h.versions.count.should   be(1)
        h.updates.should          be_empty
        
        h.creation.should_not             be_nil
        h.creation.diff.diff_type.should  == "creation"
        h.creation.diff.should            be_creation
      end
    end
  end
  
  context "when not modified" do
    before :each do
      @msg = Message.create(:title => "Hello")
      @msg.title += "Different"
      @msg.save!
    end
    
    it "should not create new versions" do
      version_count = lambda { @msg.history.versions.count }
  
      lambda do
        @msg.should_not be_new_record
        @msg.changes.should be_empty
        @msg.save!
      end.should_not change(version_count, :call)
    end
  end
  
  context "when modified" do
    it "should keep the correct value-types" do
      m = Message.create
      
      time = Time.now.utc
      date = Date.today.advance(:days => 5)
      
      m.title = "Hello there!"
      m.body = "I am no spambot."
      m.votes = 42
      m.read = true
      m.donated = 13.37
      m.published_at = time
      m.stamped_on = date
      m.save!
      
      m.history.updates.count.should == 1
      change = m.history.updates.last.diff
      changes = change.changes
      grouped = {}
      
      changes.each do |c|
        grouped[c.attribute.to_sym] = c
      end
      
      grouped[:title].new_value.should == "Hello there!"
      grouped[:title].old_value.should == nil
      
      grouped[:body].new_value.should == "I am no spambot."
      grouped[:body].old_value.should == nil
      
      grouped[:votes].new_value.should == 42
      grouped[:votes].old_value.should == 0
      
      grouped[:read].new_value.should == true
      grouped[:read].old_value.should == false
      
      grouped[:published_at].new_value.class.should == Time
      grouped[:published_at].new_value.should == Time.utc(time.year, time.month, time.day, time.hour, time.min, time.sec)
      grouped[:published_at].old_value.should == nil
      
      grouped[:stamped_on].new_value.class.should == Date
      grouped[:stamped_on].new_value.should == date
      grouped[:stamped_on].old_value.should == nil
    end
    
    it "should return changes as an hash" do
      m = Message.create(:title => "a", :votes => 1)
      
      m.title = "b"
      m.votes = 2
      m.save!
      
      diff = m.history.updates.last.diff
      diff.to_hash.should == {
        :title => ["a", "b"],
        :votes => [1, 2]
      }
    end
    
    context "on a single field" do
      before :each do
        @first_title = "Hello"
        @new_title = "Hello World"
        @msg = Message.create(:title => @first_title)
        @msg.title = @new_title
        @msg.save!
      end
    
      it "should create new versions" do
        @msg.history.tap do |h|
          h.versions.count.should         == 2
          h.original_version.title.should == @first_title
          h.previous.title.should         == @first_title
          h.latest_version.title.should   == @new_title
        end
      end
    
      it "should create an update-diff" do
        @msg.history.tap do |h|
          h.updates.count.should                == 1
          h.updates.first.diff.diff_type.should == "update"
          h.updates.first.diff.should           be_update
        
          h.creation.diff.should       == h.versions.first.diff
          h.updates.first.diff.should  == h.versions.last.diff
        end
      end
    
      it "should create attribute-diffs in update-diff" do
        @msg.history.tap do |h|
          diff = h.updates.first.diff
          diff.changes.count.should == 1
  
          diff.changes.first.tap do |attr_diff|
            attr_diff.attribute.should == "title"
            attr_diff.old_value.should == @first_title
            attr_diff.new_value.should == @new_title
          end
        end
      end
    end
    
    context "on multiple fields" do
      it "should create multiple attribute-diffs in update-diff" do
        @msg = Message.create
        
        @msg.title = "Foo"
        @msg.read = true
        @msg.save!
        
        @msg.history.versions.count.should == 2
        @msg.history.updates.count.should == 1
        
        @msg.history.tap do |h|
          changes = h.updates.first.diff.changes
          changes.count.should == 2
  
          attributes_changed = changes.collect do |change|
            change.attribute.to_s
          end
          
          Set.new(attributes_changed).should == Set.new(%w(title read))
        end
      end
    end
  end
  
  context "when restored" do
    before :each do
      @message = Message.create(:title => "one")
      @message.title = "two"
      @message.save!

      @restored = @message.history.restore(@message.history.original_version)
    end
    
    it "should contain the previous values" do
      r = @restored
      r.should_not    be_nil
      r.should        be_kind_of(Message)
      r.title.should  == "one"
    end
    
    it "should not modifiy the original" do
      @message.title.should == "two"
    end
    
    it "should be read-only" do
      lambda { @restored.save! }.should raise_exception(ActiveRecord::ReadOnlyRecord)
    end
  end
  
  it "should also accept a version number for restoration" do
    @message = Message.create(:title => "one")
    @message.update_attributes(:title => "two").should be_true
    @message.update_attributes(:title => "three").should be_true
    
    @restored = @message.history.restore(0)
    @restored.title.should == "one"
    
    @restored = @message.history.restore(1)
    @restored.title.should == "two"
    
    @restored = @message.history.restore(2)
    @restored.title.should == "three"
  end
  
  it "should raise an exception for invalid version numbers" do
    @message = Message.create(:title => "one")
    @message.history.versions.count.should == 1
    
    lambda{ @message.history.restore(-1) }.should raise_exception
    lambda{ @message.history.restore(1)  }.should raise_exception(ActiveRecord::RecordNotFound)
  end
  
  it "should allow handy queryies for restoration" do
    @message = Message.create(:title => "one")
    @message.update_attributes(:title => "two").should be_true
    
    @message.history.restore(:original).title.should == "one"
  end
  
  it "should find version-neighbors" do
    @message = Message.create(:title => "one")
    @message.update_attributes(:title => "two").should be_true
    @message.update_attributes(:title => "three").should be_true
    
    mid = @message.history.versions.skip(1).limit(1).first
    mid.title.should == "two"
    
    mid.previous_versions.count.should  == 1
    mid.next_versions.count.should      == 1
    mid.previous.should                 == @message.history.versions.skip(0).limit(1).first
    mid.next.should                     == @message.history.versions.skip(2).limit(1).first
  end
  
  it "should not break handy queries for chained restorations" do
    @message = Message.create(:title => "one")
    @message.update_attributes(:title => "two").should be_true
    @message.history.version_index.should == 1
    @message.version.should == 1
    
    previous = @message.history.restore(:previous)
    previous.history.version_index.should == 0
    previous.version.should == 0
    
    identity = previous.history.restore(:next)
    identity.history.version_index.should == 1
    identity.version.should == 1
    
    identity.should_not     be_nil
    identity.title.should   == "two"
  end
  
  context "with customization" do
    class AuditedMessage < ActiveRecord::Base
      set_table_name "messages"
      
      cattr_accessor :current_user

      extend Historical::ActiveRecord
      
      is_historical do
        meta do
          belongs_to_active_record :author, :required => true, :class_name => "User"
        end

        callback do |version|
          version.meta.author = AuditedMessage.current_user
        end
      end
    end
    
    before :each do
      AuditedMessage.current_user = nil
      Historical.boot!
    end
    
    it "should create custom keys on ModelVersion::Diffs" do
      user = User.create(:name => "Jane Doe")
      AuditedMessage.current_user = user
      
      msg = AuditedMessage.create(:title => "one")
      
      author = msg.history.versions.first.meta.author
      author.should == user
      author.id.should == user.id
    end
    
    it "should validate requirements" do
      # no author is set
      
      lambda do
        AuditedMessage.create(:title => "one")
      end.should raise_exception(MongoMapper::DocumentNotValid)
    end
  end
end
