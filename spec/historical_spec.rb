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
    
    it "should not create new versions if nothing changed" do
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
end
