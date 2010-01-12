require File.dirname(__FILE__) + '/test_helper'

class ModelFormattingTest < Test::Unit::TestCase
  it "parses simple string into array of single FormattedBlock" do
    parts = ModelFormatting.parse_text_parts(nil, nil, 'foo')
    parts.size.should == 1
    parts.first.class.should == ModelFormatting::FormattedPart
    parts.first.should == 'foo'
  end

  it "parses empty code block into array of single CodeBlock" do
    parts = ModelFormatting.parse_text_parts(nil, nil, "@@@ foo\n@@@")
    parts.size.should == 1
    parts.first.class.should == ModelFormatting::CodePart
    parts.first.should == ''
  end

  it "parses simple code block into array of single CodeBlock" do
    parts = ModelFormatting.parse_text_parts(nil, nil, "@@@ foo\nbar\n@@@")
    parts.size.should == 1
    parts.first.class.should == ModelFormatting::CodePart
    parts.first.should == 'bar'
  end

  it "parses formatted block followed by code block into array of parts" do
    parts = ModelFormatting.parse_text_parts(nil, nil, "foo \n@@@ foo\nbar\n@@@")
    parts.size.should == 2
    parts.map { |p| p.class }.should  == [ModelFormatting::FormattedPart, ModelFormatting::CodePart]
    parts.map { |p| p.simple_string }.should == ["foo ", "bar"]
  end

  it "parses code block followed by formatted block into array of parts" do
    parts = ModelFormatting.parse_text_parts(nil, nil, "@@@ foo\nbar\n@@@\n foo \n")
    parts.size.should == 2
    parts.map { |p| p.class }.should  == [ModelFormatting::CodePart, ModelFormatting::FormattedPart]
    parts.map { |p| p.simple_string }.should == ["bar", " foo "]
  end

  it "parses formatted block followed by unfinished code block" do
    parts = ModelFormatting.parse_text_parts(nil, nil, "foo \n@@@ foo\nbar\nbaz")
    parts.size.should == 2
    parts.map { |p| p.class }.should  == [ModelFormatting::FormattedPart, ModelFormatting::CodePart]
    parts.map { |p| p.simple_string }.should == ["foo ", "bar\nbaz"]
  end

  it "parses mixed blocks" do
    parts = ModelFormatting.parse_text_parts(nil, nil, "foo \n@@@ foo\nbar\nbaz\n@@@\n\nblah blah")
    parts.size.should == 3
    parts.map { |p| p.class }.should  == [ModelFormatting::FormattedPart, ModelFormatting::CodePart, ModelFormatting::FormattedPart]
    parts.map { |p| p.simple_string }.should == ["foo ", "bar\nbaz", "\nblah blah"]
  end

  it "#replace_vars replaces variables in a string with a given context" do
    ModelFormatting::Config.new(nil, nil, nil).replace_vars("a:abc/:d_e_f/:foo!", :abc => 'bc', :d_e_f => '-').should == "abc/-/!"
  end

  it "numbers lists separated by code blocks correctly" do
    ModelFormatting.process(:html, "1. Stuff\n    not code\n2. More stuff\n@@@\nmore code\n@@@\n3. Even more stuff\n        code!\n4. ending").should == \
      %(<div><ol>\n<li>Stuff<br/>\n not code</li>\n<li>More stuff<br/>\n<pre><code>more code</code>\n</pre></li>\n<li>Even more stuff<br/>\n\n\n<pre><code> code!</code></pre></li>\n<li>ending</li>\n</ol></div>)
  end
  
  it "links and encodes urls correctly" do
    ModelFormatting.process(:html, "a *b*  \n[Whoo](http://entp.com?a=1&b=2)").should == %(<div><p>a <em>b</em><br/>\n<a href="http://entp.com?a=1&amp;b=2">Whoo</a></p></div>)
  end
  
  it "converts @@@ to code blocks" do
    ModelFormatting.process(:html, "<a>foo</a>\n\n@@@\n<a>bar</a>\n@@@\n\n@@@\nbaz\n@@@\n\n@@@ wah wah \n \n").should == %(<div><p><a>foo</a></p>\n\n<pre><code>&lt;a&gt;bar&lt;/a&gt;</code>\n</pre>\n\n\n<pre><code>baz</code>\n</pre>\n\n\n<p>@@@ wah wah </p></div>)
  end
  
  it "converts @@@ with params to code blocks" do
    ModelFormatting.process(:html, "foo\n@@@ ninja\nbar\n@@@\n@@@\nbaz\n@@@\n@@@ wah wah \n \n").should == %(<div><p>foo<br/>\n<pre><code class=\"ninja\">bar</code>\n</pre>\n<pre><code>baz</code>\n</pre>\n@@@ wah wah </p></div>)
  end
  
  it "fixes irregular number of @@@'s" do
    ModelFormatting.process(:html, "foo\n@@@\nbar\n@@@\n@@@\nbaz\n@@@\n@@@ wah wah \n \n@@@").should == %(<div><p>foo<br/>\n<pre><code>bar</code>\n</pre>\n<pre><code>baz</code>\n</pre>\n@@@ wah wah </p>\n\n<pre><code></code>\n</pre></div>)
  end
  
  it "converts @@@ with params to code blocks with text format" do
    ModelFormatting.process(:text, "foo\n@@@ ninja\nbar\n@@@\n@@@\nbaz\n@@@\n@@@ wah wah \n \n").should == %(foo\nbar\nbaz\n@@@ wah wah)
  end
  
  it "fixes irregular number of @@@'s with text format" do
    ModelFormatting.process(:text, "foo\n@@@\nbar\n@@@\n@@@\nbaz\n@@@\n@@@ wah wah \n \n@@@").should == %(foo\nbar\nbaz\n@@@ wah wah)
  end
  
  it "treats linebreaks correctly" do
    ModelFormatting.process(:html, "Line breaks should not be treated as\nnew paragraphs.  They are not paragraphs.\n\nHowever, when a line is skipped, that is a paragraph.\nGMail, and basically every comment or submission form on the \nweb work this way.").should == \
      "<div><p>Line breaks should not be treated as<br/>\nnew paragraphs.  They are not paragraphs.</p>\n\n<p>However, when a line is skipped, that is a paragraph.<br/>\nGMail, and basically every comment or submission form on the<br/>\nweb work this way.</p></div>"
  end

  describe "GFM" do
    it "does not touch single underscores inside words" do
      assert_equal "foo_bar", ModelFormatting.gfm("foo_bar")
    end
  
    it "does not touch underscores in code blocks" do
      assert_equal "    foo_bar_baz", ModelFormatting.gfm("    foo_bar_baz")
    end
  
    it "does not touch underscores in pre blocks" do
      assert_equal "<pre>\nfoo_bar_baz\n</pre>", ModelFormatting.gfm("<pre>\nfoo_bar_baz\n</pre>")
    end
  
    it "escapes two or more underscores inside words" do
      assert_equal "foo\\_bar\\_baz", ModelFormatting.gfm("foo_bar_baz")
    end
  
    it "turns newlines into br tags in simple cases" do
      assert_equal "foo  \nbar", ModelFormatting.gfm("foo\nbar")
    end
  
    it "converts newlines in all groups" do
      assert_equal "apple  \npear  \norange  \nbanana\n\nruby  \npython  \nerlang  \njavascript",
        ModelFormatting.gfm("apple\npear\norange\nbanana\n\nruby\npython\nerlang\njavascript")
    end
  
    it "does not not convert newlines in lists" do
      assert_equal "# foo\n# bar", ModelFormatting.gfm("# foo\n# bar")
      assert_equal "* foo\n* bar", ModelFormatting.gfm("* foo\n* bar")
    end
  end
end