**Note:** Development just started! This document might change a lot during the next few days!

# Historical

*Historical* is yet another plugin to allow versioning of your models' data. It combines the
best features of other approaches (auditing, single table) without storing serialized
complex data-types in your relational database. This allows you to continue your work
with migrations without ending up at a point where your old versions become obsolete.

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

## Why Another Versioning Plugin?

You might have seen a lot of plugins that allow you to version your models' data, like
`acts_as_versioned`, `paper_trail`, or `vestal_versions`. While `acts_as_versioned`
has clear semantics and a good database design, it also generates much overhead. Most
other plugins try to tackle this by "only storing the changes in a single table".

The issue I had with the other approaches was that you store complex data-types
in a RDBMS. You can call me picky but I think this would be a job
for *CouchDB*. **What if I have a migration which renames column A to B?**

*Historical* is my approach to build something between `acts_as_versioned` and `paper_trail`.

## Rails Version

Developed with/for Rails 2.3.4

## Basic Usage

Setting up *Historical* only needs a single line of code in each model you want to have updates/versions for.

    class Post < ActiveRecord::Base
      historical
      
      belongs_to :author, :class_name => "Person"
      
      # ...
    end
    
### Getting Model Updates, Attribute Updates and Versions

    post = Post.find 1
    post.author                         # => <Person name="Jane">
    post.model_updates                  # => [<ModelUpdate>, <ModelUpdate>, ...]
    
    update = post.model_updates.first
    update.version                      # => 1
    update.attribute_updates            # => [<AttributeUpdate>, ...]
    
    change = update.attribute_updates.first
    change.attribute                    # => "topic"
    change.old                          # => "Hi"
    change.new                          # => "Hello"
    
    # shortcut
    update.old_topic                    # => "Hi"
    update.new_topic                    # => "Hello"


### Reverting to Older Versions

    old_post = post.as_version 1        # returns a Post instance with working (outgoing) associations
    old_post.topic                      # => "Hello"
    old_post.author                     # => <Person name="John">
    old_post.save!                      # will raise an ActiveRecord::ReadOnlyRecord exception
    
    oldest_post = post.as_version 0     # before you added historical / after post was created
    oldest_post.topic                   # => "Hi"
    

## Configure `historical`

    historical :only => [:topic]             # will only track the specified attributes
    historical :except => [:password]        # let's you restrict which attributes should be tracked
    historical :timestamps => true`          # will also track `created_at` and `updated_at` (ignored by default)


### Auto-Merging of Updates

Here is a simple szenario where auto-merging might be useful.

    post = Post.create!(:topic => "Hi")         # User A creates Post
    post.update_attributes!(:topic => "Heloo")  # User B edits topic
    post.update_attributes!(:topic => "Hello")  # User B fixes typo in topic ten seconds later

    post.model_updates.count                    # => 2

Why not only have one `ModelUpdate` because this fix was added so quick after the last version? Just
update your Post model with this:

    historical :merge => { :if_time_difference_is_less_than => 2.minutes }
  
Now let's take a look again.
    
    post = Post.create!(:topic => "Hi")         # User A creates Post
    post.update_attributes!(:topic => "Heloo")  # User B edits topic
    post.update_attributes!(:topic => "Hello")  # User B fixes typo in topic ten seconds later

    post.model_updates.count                    # => 1
    update = post.model_updates.first
    change = update.attribute_updates.first
    
    change.attribute                            # => "topic"
    change.old                                  # => "Hi"
    change.new                                  # => "Hello"
    
    # and even destruction of updates (only happens on exact reverts)
    
    post.update_attributes!(:topic => "Hi")     # User B restores topic manually
    post.model_updates.count                    # => 0


## Intellectual Property

Copyright (c) 2009 Marcel Jackwerth (marcel@northdocks.com). Released under the MIT licence.
