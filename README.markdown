**Note:** Development just started! This document might change a lot during the next few days!

# Historical

*Historical* is yet another plugin to allow versioning of your models' data. It combines the
best features of other approaches (auditing, single table) without storing serialized
complex data-types in your relational database. This allows you to continue your work
with migrations without ending up at a point where your old versions become obsolete.

## A Short Comparison

**Note:** *list taken from [`vestal_versions`](http://github.com/laserlemon/vestal_versions) GitHub page, extended by `historical`*

[`acts_as_versioned`](http://github.com/technoweenie/acts_as_versioned) by [technoweenie](http://github.com/technoweenie) was a great start,
but it failed to keep up with ActiveRecord's introduction of dirty objects in version 2.1. Additionally, each versioned model needs its own versions
table that duplicates most of the original table's columns. The versions table is then populated with records that often duplicate most of the original
record's attributes. All in all, not very DRY.

[`simply_versioned`](http://github.com/mmower/simply_versioned) by [mmower](http://github.com/mmower) started to move in the right direction by
removing a great deal of the duplication of acts_as_versioned. It requires only one versions table and no changes whatsoever to existing models.
Its versions table stores all of the model attributes as a YAML hash in a single text column. But we could be DRYer!

[`vestal_versions`](http://github.com/laserlemon/vestal_versions) by [laserlemon](http://github.com/laserlemon) keeps in the spirit of consolidating to one versions table,
polymorphically associated with its parent models. But it goes one step further by storing a serialized hash of _only_ the models'
changes. Think modern version control systems. By traversing the record of changes, the models can be reverted to any point in time.

[`historical`](http://github.com/sirlantis/historical) keeps the one versions table approach and will only store differences. However it will not store
serialized complex data-types (full models) in the database to maintain the comfort of migrations (*What if I have a migration which renames column A to B?
Will my old versions become useless?*). As a nice side-effect this allows fast reverting to previous states.

## Features

* Allows you to get **every previous version**.
* Allows you to get the **differences** between a version and the predecessor (to build a "What's new?" feature).
* Allows you to specify which attributes you want to keep versioned.
* Supports **auto-merging** of versions by time-limit or customized rules.
* Supports outgoing **associations** (belongs_to) - but will not cascade version-dates.
* Only stores differences of updated attributes.
* Does not store updates which don't change anything (or which only change attributes you are ignoring).
* Unobstrusive versioning **without serialization** of complex data-types.
* Stores everything in a single database table.
* TODO: current_user (auditing)

## Rails Version

Developed with/for Rails 2.3.4

## Installation

    cd YOUR_RAILS_APP
    
    ruby script/plugin install git://github.com/sirlantis/historical.git
    ruby script/generate historical_migration
    
    rake db:migrate

## Basic Usage

Setting up *Historical* only needs a single line of code in each model you want to have updates/versions for.

    class Post < ActiveRecord::Base
      historical
      
      belongs_to :author, :class_name => "Person"
      
      # ...
    end
    
### Getting Model Updates, Attribute Updates and Versions

    post = Post.find 1
    post.version                        # => 5
    post.author                         # => <Person name="Jane">
    post.model_updates                  # => [<ModelUpdate>, <ModelUpdate>, ...]
    
    update = post.model_updates.first
    update.version                      # => 1
    update.attribute_updates            # => [<AttributeUpdate>, ...]
    
    change = update.attribute_updates.first
    change.attribute                    # => "topic"
    change.old                          # => "Hi"
    change.new                          # => "Hello"
    
    # you might also use a shortcut
    update.old_topic                    # => "Hi"
    update.new_topic                    # => "Hello"


### Reverting to Older Versions

    old_post = post.as_version 2        # returns a Post instance with working (outgoing) associations
    old_post.topic                      # => "Hello"
    old_post.author                     # => <Person name="John">
    old_post.save!                      # will raise an ActiveRecord::ReadOnlyRecord exception
    
    oldest_post = post.as_version 1     # before you added historical / after post was created
    oldest_post.topic                   # => "Hi"
    
    previous_post = post.as_version -1  # negative numbers allow to step back
    previous_post.version               # => 4
    

## Configure `historical`

    historical :only => [:topic]             # will only track the specified attributes
    historical :except => [:password]        # let's you restrict which attributes should be tracked
    historical :timestamps => true`          # will also track `created_at` and `updated_at` (ignored by default)


### Auto-Merging of Updates

Here is a simple szenario where auto-merging might be useful.

    post = Post.create!(:topic => "Hi")         # User A creates Post
    post.update_attributes!(:topic => "Heloo")  # User B edits topic
    post.update_attributes!(:topic => "Hello")  # User B fixes typo in topic ten seconds later

    post.version                                # => 3
    post.model_updates.count                    # => 2

Why not only have one `ModelUpdate` because this fix was added so quick after the last version? Just
update your Post model with this:

    historical :merge => { :if_time_difference_is_less_than => 2.minutes }
  
Now let's take a look again.
    
    post = Post.create!(:topic => "Hi")         # User A creates Post
    post.update_attributes!(:topic => "Heloo")  # User B edits topic
    post.update_attributes!(:topic => "Hello")  # User B fixes typo in topic ten seconds later

    post.version                                # => 2
    post.model_updates.count                    # => 1
    update = post.model_updates.first
    change = update.attribute_updates.first
    
    change.attribute                            # => "topic"
    change.old                                  # => "Hi"
    change.new                                  # => "Hello"
    
    # and even destruction of updates (only happens on exact reverts)
    
    post.update_attributes!(:topic => "Hi")     # User B restores topic manually
    post.version                                # => 1
    post.model_updates.count                    # => 0

## How to Migrate?

Should you consider doing a migration on your versioned model tabel, you might need to update the `attribute_updates` table as well.

    rename_column :posts, :topic, :title
    execute "UPDATE attribute_updates upd SET upd.attribute = 'title' WHERE upd.target_type = 'Post' AND upd.attribute = 'topic'"
    

## Intellectual Property

Copyright (c) 2009 Marcel Jackwerth (marcel@northdocks.com). Released under the MIT licence.
