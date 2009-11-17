require 'test_helper'

class HistoricalTest < ActiveSupport::TestCase
  load_schema
  
  context "A person (:only => email) instance" do
    setup do
      @person = HistoricalTestModels::Person.create!(:name => "max", :email => "max@example.com")
      assert_equal 1, @person.saves.count
    end
    
    should "only track email updates" do
      @person.name = "peter"
      @person.email = "peter@example.com"
      @person.save!
      @person.reload
      
      assert_equal 2, @person.saves.count
      assert_equal 1, @person.updates.count
      assert_equal ["email"], @person.attribute_updates.collect { |x| x.attribute }
    end
  end
  
  class Account < ActiveRecord::Base
    is_historical :except => :password, :timestamps => true, :require_author => true
  end
  
  context "An Account instance" do
    setup do
      @person = HistoricalTestModels::Person.create!(:name => "max", :email => "max@example.com")
      Historical::ActionControllerExtension.historical_author = @person
      
      @account = Account.create!(:login => "jane", :password => "doe")
      @account.reload
      
      assert_equal 1, @account.saves.count
      assert_not_nil @account.creation
    end
    
    should "track timestamp updates but not password updates" do
      @account.login = "john"
      @account.password = "wayne"
      @account.save!
      @account.reload
      
      assert_equal 2, @account.saves.count
      assert_equal 1, @account.updates.count
      
      assert_equal ["login", "updated_at"].to_set, @account.attribute_updates.collect{ |x| x.attribute }.to_set
    end
    
    should "raise an exception on update if no author is given" do
      Historical::ActionControllerExtension.as_historical_author(nil) do
        assert_raise Historical::AuthorRequired do
          @account.login = "john"
          @account.save!
        end
      end
    end
    
    should "raise an exception if no author is given" do
      Historical::ActionControllerExtension.as_historical_author(nil) do
        assert_raise Historical::AuthorRequired do
          Account.create!(:login => "john", :password => "wayne")
        end
      end
    end
  end
  
  context "A Post instance" do
    setup do
      @post = HistoricalTestModels::Post.create!(:topic => "hello world", :content => "dlrow olleh")
      @post.reload
      assert_equal 1, @post.saves.count
    end
    
    context "with no changes" do     
      should "not spawn a new version when saved" do
        @post.save!
        @post.reload
        
        assert_equal 0, @post.updates.count
        assert_equal false, @post.reverted?
        assert_equal 1, @post.version
      end
    end
    
    context "with some dirty changes" do
      setup do
        @post.topic = "hello world again"
      end
      
      should "should spawn a new version when saved" do
        @post.save!
        @post.reload
        
        assert_equal 2, @post.saves.count
        assert_equal ["ModelCreation", "ModelUpdate"], @post.saves.collect{|x| x[:type]}
        assert_equal ["ModelCreation", "ModelUpdate"], @post.saves.collect{|x| x.class.name}
        
        assert_equal 1, @post.updates.count
        assert_equal 1, @post.updates.first.version
        
        assert_equal 1, @post.attribute_updates.count
        
        change = @post.attribute_updates.first
        
        assert_equal "topic", change.attribute
        assert_equal "hello world", change.old
        assert_equal "hello world again", change.new
      end
    end
  end
end
