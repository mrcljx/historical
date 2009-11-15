require 'test_helper'

class AssociationsTest < ActiveSupport::TestCase
  load_schema
  
  context "A Post instance" do
    setup do
      @john = HistoricalTestModels::Person.create!(:name => "john")
      @jane = HistoricalTestModels::Person.create!(:name => "jane")
      
      @post = HistoricalTestModels::Post.create!(:topic => "hello world", :content => "dlrow olleh")
      @post.reload
      
      @post.topic = "Amazons"
      @post.author = @jane
      @post.save!
      
      @post.topic = "Boondock"
      @post.content = "Sacred?"
      @post.author = nil
      @post.save!
      
      @post.reload
    end
    
    context "with a modified belongs_to association" do
      setup do
        @post.topic = "Who belongs to me?"
        @post.author = @john
        @post.save!
        @post.reload
      end
      
      should "report changed _id" do
        change = @post.saves.last
        assert_equal [:author_id, :topic].to_set, change.modified_attributes.to_set
      end
      
      should "hide changed _id if requested" do
        change = @post.saves.last
        assert_equal [:topic].to_set, change.modified_attributes_without_associations.to_set
      end
      
      should "report the changed association as a modification" do
        change = @post.saves.last
        assert_equal [:author, :topic].to_set, change.modifications.to_set
      end
    end
    
    context "with a modified polymorphic belongs_to association" do
      setup do
        @post.topic = "Who belongs to me?"
        @post.parent = @jane
        @post.save!
        @post.reload
      end
      
      should "report changed _id and _type" do
        change = @post.saves.last
        assert_equal [:parent_id, :parent_type, :topic].to_set, change.modified_attributes.to_set
      end
      
      should "hide changed _id and_type if requested" do
        change = @post.saves.last
        assert_equal [:topic].to_set, change.modified_attributes_without_associations.to_set
      end
      
      should "report the changed association as a modification" do
        change = @post.saves.last
        assert_equal [:parent, :topic].to_set, change.modifications.to_set
      end
      
      should "support support queries for new and old values" do
        change = @post.saves.last
        assert_equal nil, change.old_parent
        assert_equal @jane, change.new_parent
      end
      
      should "support support queries even if only the id changed" do
        @post.parent = @john
        @post.save!
        @post.reload
        
        change = @post.saves.last
        assert_equal @jane, change.old_parent
        assert_equal @john, change.new_parent
        
        # to other
        
        @post.parent = @jane
        @post.save!
        @post.reload
        
        change = @post.saves.last
        assert_equal @john, change.old_parent
        assert_equal @jane, change.new_parent
        
        # to self
        
        @post.parent = @post
        @post.save!
        @post.reload
        
        change = @post.saves.last
        assert_equal @jane, change.old_parent
        assert_equal @post, change.new_parent
        
        # to nil
        
        @post.parent = nil
        @post.save!
        @post.reload
        
        change = @post.saves.last
        assert_equal @post, change.old_parent
        assert_equal nil, change.new_parent
      end
    end
  end
end
