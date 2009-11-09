require 'test_helper'

class MergeTest < ActiveSupport::TestCase
  context "A Post instance" do
    setup do
      @post = Post.create!(:topic => "hello world", :content => "dlrow olleh")
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
  end
end