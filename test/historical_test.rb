require 'test_helper'

class HistoricalTest < ActiveSupport::TestCase
  load_schema
  
  context "A Post instance" do
    setup do
      @post = Post.create!(:topic => "hello world", :content => "dlrow olleh")
    end
    
    context "with no changes" do     
      should "not spawn a new version when saved" do
        @post.save!
        @post.reload
        assert_equal 0, @post.versions.count
      end
    end
    
    context "with some dirty changes" do
      setup do
        @post.topic = "hello world again"
      end
      
      should "should spawn a new version when saved" do
        @post.save!
        @post.reload
        
        assert_equal 1, @post.versions.count
        assert_equal 1, @post.attribute_changes.count
        
        change = @post.attribute_changes.first
        
        assert_equal "topic", change.attribute
        
        assert_equal "hello world", change.old_value
        assert_equal String, change.old_class.constantize
        
        assert_equal "hello world again", change.new_value
        assert_equal String, change.new_class.constantize
      end
    end
  end
end
