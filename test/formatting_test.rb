require File.dirname(__FILE__) + '/test_helper'

module ModelFormatting
  class Test < Test::Unit::TestCase
    class Base < Struct.new(:body, :formatted_body, :title, :title_html, :bio, :full_bio)
      ModelFormatting::Init.setup_on self
      class_inheritable_accessor :before_save_callback

      def self.before_save(method = nil)
        if method
          self.before_save_callback = method
        else
          before_save_callback
        end
      end

      def save
        send self.class.before_save
      end
    end

    class Simple < Base
      formats :body
    end
  
    describe "Simple with formatting" do
      it "has attribute from #formats arguments" do
        Simple.model_formatting_attributes[:body].should == "formatted_body"
      end

      it "sets before_save callback" do
        Simple.before_save.should == :format_content_with_model_formatting
      end
  
      it "formats all fields" do
        record = Simple.new
        record.body = 'booya'
        record.save
        record.formatted_body.should == %(<div><p>booya</p></div>)
      end
      
      it "bolds the string 'Name'" do
        record = Simple.new
        record.body = "My name is\n__Name__"
        record.save
        record.formatted_body.should == %(<div><p>My name is<br />\n<strong>Name</strong></p></div>)
      end

      it "preserves leading spaces in code blocks" do
        record = Simple.new
        record.body = "    code\n    more code\n\nnot code\n\n"
        record.save
        record.formatted_body.should == %(<div><pre><code>code\nmore code</code></pre>\n\n<p>not code</p></div>)
      end
    end

    class BaseWithAfter < Base
      formats :body do
        after { |format, text, options| text }
      end
    end

    describe "base with after callback" do
      it "does not leave mkd-extraction artifacts" do
        record = BaseWithAfter.new
        record.body = File.read(File.dirname(__FILE__) + '/fixtures/mkd-extraction.txt')
        record.save
        assert_no_match /mkd-extraction/, record.formatted_body
      end
    end

    class Post < Base
      formats :body, :title => :title_html do
        attributes[:bio] = :full_bio

        white_list.allowed_tags << 'table'

        before do |format, text, options|
          text.reverse!
          text
        end

        after do |format, text, options|
          "(#{text.strip})"
        end
      end
    end
  
    describe "Post with formatting" do
      it "has attribute from #formats arguments" do
        Post.model_formatting_attributes[:body].should == "formatted_body"
      end
  
      it "has attribute added from #formats options hash" do
        Post.model_formatting_attributes[:title].should == :title_html
      end
  
      it "has attribute added from #attributes  options hash" do
        Post.model_formatting_attributes[:bio].should == :full_bio
      end
  
      it "has white list sanitizer that allows table tags" do
        Post.model_formatting_white_list.allowed_tags.should include('table')
      end
  
      it "sets before_save callback" do
        Post.before_save.should == :format_content_with_model_formatting
      end

      describe "being saved" do
        before :all do
          @record = Post.new
          @record.body  = 'booya'
          @record.title = 'wtf'
          @record.save
        end

        it "formats #body" do
          @record.formatted_body.should == %(<div>(<p>ayoob</p>)</div>)
        end

        it "formats #title" do
          @record.title_html.should == %(<div>(<p>ftw</p>)</div>)
        end

        it "formats #bio" do
          @record.full_bio.should == ''
        end
      end
    end

    class ChildPost < Post
      formats do
        attributes.delete :bio

        before do |format, text, options|
          text.upcase!
          text
        end

        after do |format, text, options|
          text
        end
      end
    end
  
    describe "ChildPost with formatting" do
      it "has attribute from #formats arguments" do
        ChildPost.model_formatting_attributes[:body].should == "formatted_body"
      end
  
      it "has attribute added from #formats options hash" do
        ChildPost.model_formatting_attributes[:title].should == :title_html
      end
  
      it "removes attribute added from superclass#attributes options hash" do
        ChildPost.model_formatting_attributes.keys.should_not include(:bio)
      end
  
      it "sets before_save callback" do
        ChildPost.before_save.should == :format_content_with_model_formatting
      end

      describe "being saved" do
        before :all do
          @record = ChildPost.new
          @record.body = 'booya'
          @record.bio  = 'wtf'
          @record.save
        end

        it "formats #body" do
          @record.formatted_body.should == %(<div><p>BOOYA</p></div>)
        end

        it "skips #bio" do
          @record.full_bio.should == nil
        end
      end
    end
  end
end
      
