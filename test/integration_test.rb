require 'test_helper'

class IntegrationTest < ActiveSupport::TestCase
  load_schema
  
  class MyController < ActionController::Base
    attr_accessor :current_user
    
    def sample_action(&block)
      raise "no block given" unless block_given?
      filters = self.class.filter_chain.select(&:around?).map(&:method)
      
      # note: doesn't behave like this normally
      self.send filters.last, &block
    end
  end
  
  context "A Controller" do
    setup do
      @controller = MyController.new
      @by = HistoricalTestModels::Person.create!(:name => "John")
      @post = HistoricalTestModels::Post.create!(:topic => "hello world", :content => "dlrow olleh")
      @controller.current_user = @by
      
      assert_equal @by, @controller.current_user
    end
    
    should "set the historical_author" do
      @controller.sample_action do
        assert_equal @by, @post.historical_author, "filter wasn't called"
      end
    end
    
    should "set the author of upcoming changes" do
      @controller.sample_action do
        @post.update_attributes!(:topic => "hi")
        @post.reload
      
        assert_equal @by, @post.updates.first.author
      end
    end
    
    should "allow custom authors to be set" do
      @controller.sample_action do
        HistoricalTestModels::Person.as_historical_author(nil) do
          assert_equal nil, @post.historical_author
        end
        assert_equal @by, @post.historical_author
      end
    end
    
    should "set the custom author of upcoming changes" do
      @controller.sample_action do
        HistoricalTestModels::Person.as_historical_author(nil) do
          @post.update_attributes!(:topic => "hi")
          @post.reload
        
          assert_equal nil, @post.updates.first.author
        end
      end
    end
  end
end