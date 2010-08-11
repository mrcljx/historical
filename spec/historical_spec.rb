require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Historical" do
  class Message < ActiveRecord::Base
    extend Historical::ActiveRecord
    is_historical
  end
  
  it "should be able to create AR records" do
    msg = Message.new(:title => "Hello")
    
    msg.save.should be_true
  end
  
  it "should create Version and Diff on creation" do
    msg = Message.create(:title => "Hello")
    
    msg.history.versions.count.should be(1)
    msg.history.diffs.count.should be(1)
    msg.history.diffs.first.diff_type.should == "creation"
  end
  
  it "should not create new versions if nothing changed" do
    msg = Message.new(:title => "Hello")
    
    version_count = lambda { msg.history.versions.count }
    diff_count    = lambda { msg.history.diffs.count }
    
    version_count.call.should be(0)
    diff_count.call.should be(0)

    lambda do 
      lambda do
        msg.save!
      end.should change(version_count, :call).by(1)
    end.should change(diff_count, :call).by(1)
    
    lambda do 
      lambda do
        10.times { msg.save! }   
      end.should_not change(version_count, :call)
    end.should_not change(diff_count, :call)
  end
  
  context "when modified" do
    before :each do
      @first_title = "Hello"
      @msg = Message.create(:title => @first_title)
      @msg.title += " World!"
      @msg.save!
    end
    
    it "should create diffs" do
      versions = @msg.history.versions
      versions.should_not be_empty
    
      versions.first.title.should == @first_title
      
      @msg.history.diffs.count.should == 2
    
      model_diff = @msg.history.diffs.sort(:created_at.desc, :id.desc).first
      model_diff.diff_type.should == "update"
      model_diff.changes.count.should == 1
    
      diff = model_diff.changes.first
    
      diff.attribute.should == "title"
      diff.old_value.should == @first_title
      diff.new_value.should == @msg.title
    end
  end
end
