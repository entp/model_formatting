require 'cgi'
require 'active_support' # NilClass#blank?
module ModelFormatting
  class Part < Array
    attr_reader :format
    def initialize(format, *args)
      @format = format
      @simple_string = @formatted_string = nil
      super(*args)
    end

    def <<(s)
      @simple_string = @formatted_string = nil
      super
    end

    def compact!
      @simple_string = @formatted_string = nil
      super
    end

    def simple_string
      @simple_string ||= join("\n")
    end

    def formatted_string
      @formatted_string ||= begin
        if @format == :html
          %(<pre><code#{%( class="#{@class_name}") unless @class_name.blank?}>#{simple_string}</code></pre>)
        else
          simple_string
        end
      end
    end

    def ==(other)
      simple_string == other
    end

    def inspect
      "#{self.class.name}: #{simple_string.inspect}"
    end
  end

  class CodePart < Part
    attr_reader :class_name

    def initialize(format, class_name, *args)
      @class_name = class_name
      super(format, *args)
    end

    def <<(s)
      super CGI.escapeHTML(s)
    end
  end

  class FormattedPart < Part
    attr_reader :options

    def initialize(format, options = {}, *args)
      @options = options || {}
      super(format, *args)
    end

    def formatted_string
      @formatted_string ||= begin
        str = simple_string
        str = @options[:before].call(@format, str, @options) if @options[:before]
        str
      end
    end
  end

  def self.process(format, text, options = {})
    parts  = parse_text_parts(format, options, text)
    string = parts.map { |p| p.formatted_string } * "\n"
    string.gsub! /\r/, ''
    if format == :html
      string.gsub! /code><\/pre>/, "code>\n</pre>" # do this so markdown registers ending </pre>'s as a linebreak
      string = gfm(string)
      string = process_markdown(string)
      string.gsub! /\s+<\/code>/, '</code>' # clear linebreak preceding closing <code>
    end
    if options[:after]
      extract_tag(string, :pre, :code) do |str|
        str.replace options[:after].call(format, str, options)
      end
    end
    if format == :html
      if options[:white_list]
        string = options[:white_list].sanitize(string)
      end
      string = process_tidy(string)
    end
    string.strip!
    format == :html ? "<div>#{string}</div>" : string
  end

  CODEBLOCK_RE = /^@@@( ([a-z]+)\s*)?$/

  # Parse a string into a given array of [CodeBlcok, FormattedBlock, CodeBlock, FormattedBlock]
  #
  #   @@@ my code block
  #   @@@ end code block
  #
  #   Blah blah formatted block
  #
  #   @@@ my code block
  #   @@@ end code block
  #
  #   Blah blah formatted block
  def self.parse_text_parts(format, options, text)
    parts = []
    current_part  = nil
    in_code_block = false
    text.split("\n").each do |line|
      if line.rstrip =~ CODEBLOCK_RE
        line.rstrip!
        if in_code_block
          parts << current_part
          current_part = nil
        else
          if current_part then parts << current_part end
          current_part = CodePart.new(format, $2)
        end
        in_code_block = !in_code_block
      else
        if !in_code_block && current_part.is_a?(CodePart)
          parts << current_part
          current_part = nil
        end
        current_part ||= FormattedPart.new(format, options)
        current_part << line
      end
    end
    parts << current_part if current_part
    parts.compact!
    parts.each { |p| p.compact! }
  end

  def self.extract_regex(text, *regexes)
    # Extract pre blocks
    extractions = {}
    regexes.each do |regex|
      text.gsub!(regex) do |match|
        md5 = Digest::MD5.hexdigest(match)
        extractions[md5] ||= []
        extractions[md5] << match
        "{mkd-extraction-#{md5}}"
      end
    end
    yield text
    # In cases where multiple tag names are provided AND the tags mismatch or
    # overlap in non-conforming ways, it's possible for extracted sections to
    # have extractions in them. To keep content from being eaten by the markdown
    # extractor, loop until all of the extractions have been replaced.
    while !extractions.keys.empty?
      # Insert block extractions
      text.gsub!(/\{mkd-extraction-([0-9a-f]{32})\}/) do
        value = extractions[$1].pop
        extractions.delete($1) if extractions[$1].empty?
        value
      end
    end
    text
  end

  def self.tag_name_to_regex(name)
    %r{<#{name}[^>]*>.*?</#{name}>}m
  end

  def self.extract_tag(text, *tag_names)
    extract_regex text, *tag_names.map { |n| tag_name_to_regex(n) } do |text|
      yield text
    end
  end

  def self.gfm(text)
    extract_tag(text, :pre) do |txt| 
      # prevent foo_bar_baz from ending up with an italic word in the middle
      text.gsub!(/(^(?! {4}|\t)\w+_\w+_\w[\w_]*)/) do |x|
        x.gsub('_', '\_') if x.split('').sort.to_s[0..1] == '__'
      end

      # in very clear cases, let newlines become <br /> tags
      #text.gsub!(/(\A|^$\n)(^\w[^\n]*\n)(^\w[^\n]*$)+/m) do |x|
      #  x.gsub(/^(.+)$/, "\\1  ")
      text.gsub!(/^[\w\<][^\n]*\n+/) do |x|
        x =~ /\n{2}/ ? x : (x.strip!; x << "  \n")
      end
    end
  end

  begin
    require 'redcarpet'
    def self.process_markdown(text)
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
        :no_intra_emphasis => true,
        :tables => true,
        :fenced_code_blocks => true,
        :space_after_headers => true,
#        :hard_wrap => true, 
#        :with_toc_data => true, 
        :autolink => true).render(text)
    end
  rescue LoadError
    puts "No Redcarpet gem found.  `gem install redcarpet`."
    def self.process_markdown(text)
      text
    end
  end

  begin
    require 'tidy_ffi'
    def self.process_tidy(text)
      tidy = TidyFFI::Tidy.new(text)
      tidy.options.input_encoding = 'utf8'
      tidy.options.show_body_only = true
      tidy.options.new_inline_tags = "video source"
      tidy.options.force_output = true
      tidy.clean.strip
    end
  rescue LoadError
    puts "No TidyFFI gem found.  `gem install tidy_ffi`."
    def self.process_tidy(text)
      text
    end
  end
end
