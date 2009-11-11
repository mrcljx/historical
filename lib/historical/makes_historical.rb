module Historical::ActionControllerExtension
  
  @@historical_author = nil
  def self.historical_author; @@historical_author; end
  def self.historical_author=(value); @@historical_author = value; end
  
  def self.included(base)
    base.around_filter :with_historical_author
  end
  
  def self.as_historical_author(author)
    raise "no block given" unless block_given?
    old_author = self.historical_author
    begin
      self.historical_author = author
      yield
    ensure
      self.historical_author = old_author
    end
  end
 
  private
 
  def with_historical_author(&block)
    raise "no block given" unless block_given?
    author = self.current_user rescue nil
    Historical::ActionControllerExtension.as_historical_author(author, &block)
  end
end
 
ActionController::Base.send :include, Historical::ActionControllerExtension