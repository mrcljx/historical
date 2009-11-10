require 'test_helper'

class HistoricalTest < ActiveSupport::TestCase
  load_schema
  
  context "A person (:only => email) instance" do
    setup do
      @person = HistoricalTestModels::Person.create!(:name => "max", :email => "max@example.com")
    end
    
    should "only track email updates" do
      @person.name = "peter"
      @person.email = "peter@example.com"
      @person.save!
      @person.reload
      
      assert_equal 1, @person.updates.count
      assert_equal ["email"], @person.attribute_updates.collect { |x| x.attribute }
    end
  end
  
  class Account < ActiveRecord::Base
    historical :except => :password, :timestamps => true
  end
  
  context "An account instance" do
    setup do
      @account = Account.create!(:login => "jane", :password => "doe")
    end
    
    should "track timestamp updates but not password updates" do
      @account.login = "john"
      @account.password = "wayne"
      @account.save!
      @account.reload
      
      assert_equal 1, @account.updates.count
      assert_equal ["login", "updated_at"].to_set, @account.attribute_updates.collect{ |x| x.attribute }.to_set
    end
  end
  
  context "A Post instance" do
    setup do
      @post = HistoricalTestModels::Post.create!(:topic => "hello world", :content => "dlrow olleh")
    end
    
    context "with no changes" do     
      should "not spawn a new version when saved" do
        @post.save!
        @post.reload
        assert_equal 0, @post.updates.count
      end
    end
    
    context "with some dirty changes" do
      setup do
        @post.topic = "hello world again"
      end
      
      should "should spawn a new version when saved" do
        @post.save!
        @post.reload
        
        assert_equal 1, @post.updates.count
        assert_equal 1, @post.attribute_updates.count
        
        change = @post.attribute_updates.first
        
        assert_equal "topic", change.attribute
        assert_equal "hello world", change.old
        assert_equal "hello world again", change.new
      end
    end
  end
end
