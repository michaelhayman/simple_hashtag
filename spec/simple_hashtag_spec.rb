require 'spec_helper'

describe SimpleHashtag do

  describe ".hashtag" do
    context "regex" do
      it "match valid hashtags" do
        text = "#It is a dangerous business, #Frodo, going out your door."
        text += "You step onto #the-road,"
        text += "and if you don't keep #your_feet,"
        text += "there's no #know1ng where you might be swept off to."
        match = Post.new().scan_for_hashtags(text)
        match.should eq [["#It", "It"], ["#Frodo", "Frodo"], ["#the-road", "the-road"], ["#your_feet", "your_feet"], ["#know1ng", "know1ng"]]
      end

      it "doesn't match things that look like hashtags but are not" do
        text = "And some things that should not # have been forgotten were lost."
        text += "History became legend#. Legend became myth."
        text += "And for #2500 years, the ring﻿ passed out of all knowledge."
        match = Post.new().scan_for_hashtags(text)
        match.should eq []
      end
    end

    it "returns a string when asked to" do
      tag = SimpleHashtag::Hashtag.new(name: "RubyRocks")
      tag.to_s.should eq "rubyrocks"
      tag.to_s.should be_a(String)
    end

    it "downcase a parsed tag" do
      tag = SimpleHashtag::Hashtag.new(name: "WEirDcasE")
      tag.name.should eq "weirdcase"
    end

    it "finds a mis-cased tag" do
      SimpleHashtag::Hashtag.connection.execute("INSERT INTO simple_hashtag_hashtags (name) values ('WEirDcasE')")
      tag = SimpleHashtag::Hashtag.find_by_name("WEIRDCASE")
      tag.should_not eq nil
      tag.should be_a(SimpleHashtag::Hashtag)
      tag.name.should eq "weirdcase"
    end

    it "knows about its hashtaggables" do
      Post.create(body: "I thought up an ending for my #book.")
      Picture.create(caption: "Some who have read the #book.")

      tag = SimpleHashtag::Hashtag.find_by_name("book")
      tag.hashtaggables.size.should eq 2
      tag.hashtaggables.first.body.should eq "I thought up an ending for my #book."
      tag.hashtaggables.last.caption.should eq "Some who have read the #book."
    end

    it "can clean the DB from orphan tags" do
      Post.create(body: "Certainty of death, small #chance of success.")
      p = Post.last
      p.body = "What are we #waiting for?"
      p.save
      SimpleHashtag::Hashtag.clean_orphans

      SimpleHashtag::Hashtag.all.map(&:name).should_not include "chance"
    end
  end

  describe ".hashtaggable" do
    it "store a hashtag" do
      Post.create(body: "Don't go where I can't #follow.")
      p = Post.last
      p.hashtags.count.should eq 1
      p.hashtags.last.name.should eq "follow"
    end

    it "reflect a change" do
      Post.create(body: "Certainty of death, small #chance of success.")
      p = Post.last
      p.body += "What are we #waiting for?"
      p.save

      p.hashtags.count.should eq 2
      p.hashtags.last.name.should eq "waiting"
    end

    it "can have an empty attribute" do
      Post.create()
    end

    it "can have multiple hashtags" do
      Post.create(body: "The grey #rain-curtain of this world rolls back, and all turns to #silver glass, and then you #see it.")
      p = Post.last

      p.hashtags.count.should eq 3
      p.hashtags.map(&:to_s).should eq ["rain-curtain", "silver", "see"]
    end

    it "handles a model with custom attribute" do
      Picture.create(caption: "The grey #rain-curtain of this world rolls back, and all turns to #silver glass, and then you #see it.")
      p = Picture.last

      p.hashtags.count.should eq 3
      p.hashtags.map(&:to_s).should eq ["rain-curtain", "silver", "see"]
    end
  end
end
