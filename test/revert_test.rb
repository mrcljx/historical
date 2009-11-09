require 'test_helper'

class MergeTest < ActiveSupport::TestCase
  load_schema
  
  context "A Post instance with some versions" do
    setup do
      @post = Post.create!(:topic => "Sweet", :content => "Home Sweet Home")
      @post.update_attributes!(:topic => "Sugar", :content => "Baby")
      @post.update_attributes!(:topic => "Summer", :content => "I know what you did!") # version = 2
      @post.update_attributes!(:topic => "Amazons")
      @post.update_attributes!(:topic => "Boondock", :content => "Sacred?")
      @post.update_attributes!(:topic => "Locke", :content => "He can walk!")
      @post.reload
      
      assert_equal 5, @post.versions(:reload).count
      assert_equal [1,2,3,4,5].to_set, @post.versions.collect{ |v| v.version }.to_set
    end
    
    should "be able to time-travel" do
      @old = @post.as_version(4)
      assert_equal "Boondock", @old.topic
      assert_equal "Sacred?", @old.content
    end
    
    should "be able to time-travel over gaps" do
      @old = @post.as_version(2)
      assert_equal "Summer", @old.topic
      assert_equal "I know what you did!", @old.content
    end
    
    should "be able to time-travel to gaps" do
      @old = @post.as_version(3) # version 3 doesn't ave the :content attribute
      assert_equal "Amazons", @old.topic 
      assert_equal "I know what you did!", @old.content
    end
    
    should "be able to time-travel back to big bang" do
      @old = @post.as_version(0)
      assert_equal "Sweet", @old.topic
      assert_equal "Home Sweet Home", @old.content
    end
    
    should "allow time-travel to self" do
      assert_nothing_raised do
        @post.as_version(@post.versions.most_recent.first.version)
      end
    end
    
    should "not allow time-travel to the future" do
      assert_raise ActiveRecord::RecordNotFound do
        @post.as_version(@post.versions.most_recent.first.version + 1)
      end
    end
    
    should "not allow to find negative version numbers" do
      assert_raise ActiveRecord::RecordNotFound do
        @post.as_version(-1)
      end
    end
    
    context "reverted back" do
      setup do
        @reverted = @post.as_version(1)
        assert_equal "Sugar", @reverted.topic
      end
      
      should "allow additional reverts" do
        @grandpa = @reverted.as_version(0)
        assert_equal "Sweet", @grandpa.topic
      end
      
      should "not allow saves" do
        assert_raise TypeError do
          @reverted.save! # can't modify frozen hash
        end
      end
      
      should "not allow modifications" do
        assert_raise TypeError do
          @reverted["topic"] = "hack" # can't modify frozen hash
        end
      end
    end
  end
end