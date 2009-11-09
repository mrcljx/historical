require 'test_helper'

class HistoricalTest < ActiveSupport::TestCase
  load_schema
  
  class Post < ActiveRecord::Base
    historical :merge => { :if_time_difference_is_less_than => 2.minutes }
  end
  
  class Person < ActiveRecord::Base
    historical :only => :email
  end
  
  class Account < ActiveRecord::Base
    historical :except => :password, :timestamps => true
  end
  
  context "A mergeable Post instance" do
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
    
    context "which has been changed a minute ago" do
      setup do
        @post.topic = "hello world again"
        @post.save!
        @post.reload
        @post.versions.first.update_attributes!(:created_at => 1.minute.ago)
        @post.reload
      end
      
      should "merge changes within a specified time distance" do
        @post.topic = "bye world"
        @post.content = "i leave you now"
        @post.save!
        @post.reload
        
        assert_equal 1, @post.versions.count
        assert_equal 2, @post.attribute_changes.count
        
        topic_change = @post.attribute_changes(:reload).find_by_attribute('topic')
        assert_not_equal nil, topic_change
        
        # should have eliminated the "hello world again"
        assert_equal "hello world", topic_change.old
        assert_equal "bye world", topic_change.new
        
        content_change = @post.attribute_changes(:reload).find_by_attribute('content')
        assert_not_equal nil, content_change
        
        assert_equal "dlrow olleh", content_change.old
        assert_equal "i leave you now", content_change.new
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
