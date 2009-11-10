require 'test_helper'

class RevertTest < ActiveSupport::TestCase
  load_schema
  
  context "A Post instance with some updates" do
    setup do
      @john = HistoricalTestModels::Person.create!(:name => "john")
      @jane = HistoricalTestModels::Person.create!(:name => "jane")
      
      @post = HistoricalTestModels::Post.create!(:topic => "Sweet", :content => "Home Sweet Home", :author_id => @john.id) #v1
      @post.update_attributes!(:topic => "Sugar", :content => "Baby")
      @post.update_attributes!(:topic => "Summer", :content => "I know what you did!") # v3
      @post.update_attributes!(:topic => "Amazons", :author_id => @jane.id)
      @post.update_attributes!(:topic => "Boondock", :content => "Sacred?", :author_id => @john.id)
      @post.update_attributes!(:topic => "Locke", :content => "He can walk!", :author_id => @jane.id) # v6
      @post.reload
      
      assert_equal @jane, @post.author
      
      assert_equal false, @post.reverted?
      assert_equal 6, @post.latest_version
      assert_equal 6, @post.version
      
      assert_equal 5, @post.model_updates.count
      assert_equal [1,2,3,4,5].to_set, @post.model_updates.collect{ |v| v.version }.to_set
    end
    
    should "be able to time-travel" do
      @old = @post.as_version(5)
      assert_equal "Boondock", @old.topic
      assert_equal "Sacred?", @old.content
      assert_equal @john, @old.author
      assert_equal true, @old.reverted?
    end
    
    should "be able to time-travel over gaps" do
      @old = @post.as_version(3)
      assert_equal "Summer", @old.topic
      assert_equal "I know what you did!", @old.content
      assert_equal @john, @old.author
      assert_equal true, @old.reverted?
    end
    
    should "be able to time-travel to gaps" do
      @old = @post.as_version(4) # version 3 doesn't ave the :content attribute
      assert_equal "Amazons", @old.topic 
      assert_equal "I know what you did!", @old.content
      assert_equal @jane, @old.author
      assert_equal true, @old.reverted?
    end
    
    should "be able to time-travel back to initial version" do
      @old = @post.as_version(1)
      assert_equal "Sweet", @old.topic
      assert_equal "Home Sweet Home", @old.content
      assert_equal @john, @old.author
      assert_equal true, @old.reverted?
    end
    
    should "allow time-travel to self" do
      assert_equal 6, @post.latest_version
      
      assert_nothing_raised do
        @old = @post.as_version(6)
      end
      
      assert_equal @post.topic, @old.topic
      assert_equal @post.content, @old.content
      assert_equal @post.author, @old.author
      
      assert_equal false, @old.reverted?
    end
    
    should "not allow time-travel to the future" do
      assert_raise ActiveRecord::RecordNotFound do
        @post.as_version(@post.version + 1)
      end
    end
    
    should "not allow time-travel to big bang" do
      assert_raise ActiveRecord::RecordNotFound do
        @post.as_version(0)
      end
    end
    
    should "allow getting previous versions with negative numbers" do
      @old = @post.as_version(-1)
      assert_equal @post.version - 1, @old.version
    end
    
    should "not allow negative numbers" do
      @old = @post.as_version(1)
      assert_raise ActiveRecord::RecordNotFound do
        @old.as_version(-1)
      end
      assert_raise ActiveRecord::RecordNotFound do
        @old.as_version(-2)
      end
    end
    
    should "get changes on version" do
      @version = @post.updates.find_by_version(5)
      assert_equal @jane, @version.new_author
      assert_equal @john, @version.old_author
    end
    
    context "reverted back" do
      setup do
        @reverted = @post.as_version(2)
        assert_equal "Sugar", @reverted.topic
        assert_equal true, @reverted.reverted?
      end
      
      should "allow additional reverts" do
        @grandpa = @reverted.as_version(1)
        assert_equal "Sweet", @grandpa.topic
        assert_equal true, @grandpa.reverted?
      end
      
      should "not allow saves" do
        assert_raise ActiveRecord::ReadOnlyRecord do
          @reverted.save! # can't modify frozen hash
        end
      end
    end
  end
end