require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "A historical model" do
  class Message < ActiveRecord::Base
    extend Historical::ActiveRecord
    is_historical
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
        h.diffs.count.should      be(1)
        h.updates.should          be_empty
        
        h.creation.should_not     be_nil
        h.creation.diff_type.should == "creation"
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
      diff_count    = lambda { @msg.history.diffs.count }
    
      lambda do 
        lambda do
          @msg.save!
        end.should_not change(version_count, :call)
      end.should_not change(diff_count, :call)
    end
  end
  
  context "when modified" do
    it "should keep the correct value-types" do
      m = Message.create
      
      time = Time.now
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
      change = m.history.updates.last
      change.reload
      changes = change.changes
      grouped = {}
      
      changes.each do |c|
        grouped[c.attribute.to_sym] = c
      end
      
      grouped[:title].new_value == "Hello there!"
      grouped[:title].old_value == nil
      
      grouped[:body].new_value == "I am no spambot."
      grouped[:body].old_value == nil
      
      grouped[:votes].new_value == 42
      grouped[:votes].old_value == nil
      
      grouped[:read].new_value == true
      grouped[:read].old_value == false
      
      grouped[:published_at].new_value.class.should == Time
      grouped[:published_at].new_value == time
      grouped[:published_at].old_value == nil
      
      grouped[:stamped_on].new_value.class.should == Date
      grouped[:stamped_on].new_value == date
      grouped[:stamped_on].old_value == nil
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
          h.latest_version.title.should   == @new_title
        end
      end
    
      it "should create an update-diff" do
        @msg.history.tap do |h|
          h.updates.count.should            == 1
          h.updates.first.diff_type.should  == "update"
        
          h.creation.should       == h.diffs.first
          h.updates.first.should  == h.diffs.last
        end
      end
    
      it "should create attribute-diffs in update-diff" do
        @msg.history.tap do |h|
          model_diff = h.updates.first
          model_diff.changes.count.should == 1
  
          model_diff.changes.first.tap do |diff|  
            diff.attribute.should == "title"
            diff.old_value.should == @first_title
            diff.new_value.should == @new_title
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
        
        @msg.history.tap do |h|
          changes = h.updates.first.changes
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
end
