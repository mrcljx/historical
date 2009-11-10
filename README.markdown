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

## Why another versioning plugin?

You might have seen a lot of plugins that allow you to version your models' data, like
`acts_as_versioned`, `paper_trail`, or `vestal_versions`. While `acts_as_versioned`
has clear semantics and a good database design, it also generates much overhead. Most
other plugins try to tackle this by "only storing the changes in a single table".

The issue I had with the other approaches was that you store complex data-types
in a RDBMS. You can call me picky but I think this would be a job for *CouchDB*. 

* What if I have a migration which renames column A to B?

*Historical* is my approach to build something between`acts_as_versioned` and `paper_trail`.

## Rails Version

Developed with/for Rails 2.3.4

## Basic Usage

Setting up *Historical* only needs a single line of code in each model you want to have versions for.

    class Post < ActiveRecord::Base
      historical
      belongs_to :author, :class_name => "Person"
    end
    
You can retrieve the history through the `versions` association.

    post = Post.find 1
    post.versions             #=> [<Version>, <Version>, ...]

Each version has many `AttributeUpdate`s linked to it. You can get them via `version.attribute_updates`. These
will then have a `old` and a `new` value.

You can get a previous state of a model by using `as_version(version_number)`. The version number is stored in
`version.version`. Using `version_number = 0` will return the initial state of the model (after it was created /
before you added `historical` to the model).

    post = Post.find 1
    old_post = post.as_version(3)
    
The states returned by `as_version` will be `readonly!`.

## Configure `historical`

* `:only => [:topic]` will only track the specified attributes.
* `:except => [:password]` let's you restrict which attributes should be tracked.
* `:timestamps => true` will make Historical to track `created_at` and `updated_at` (which are ignored by default).

## Auto-Merging of Versions

In some cases you might want to automatically merge versions just to avoid unnecessary noise.

* User A creates a Post with `Hi` as the topic.
* User B changes the topic to `Hellow`
* User B fixes the typo and changes the topic to `Hello` (only one minute later).

You can enable this behavior by calling `historical`with

* `:merge => {...}` Allows you to enable auto-merging of versions.
  * `:if_time_difference_is_less_than => 3.seconds`

## Intellectual Property

Copyright (c) 2009 Marcel Jackwerth (marcel@northdocks.com). Released under the MIT licence.
