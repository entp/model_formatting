# Used to configure model formatting for a specific class. See ModelFormatting::Init
class ModelFormatting::Config
  attr_reader :white_list, :attributes, :context, :before_callback, :after_callback

  def initialize(white_list, attributes, context)
    @before_callback = nil
    @after_callback  = nil
    @white_list      = white_list
    @attributes      = attributes
    @context         = context
  end

  def before(&block)
    @before_callback = block
  end

  def after(&block)
    @after_callback = block
  end

  # replace vars in the string with a symbolized key of the same name in the context.
  def replace_vars(string, context)
    string.gsub!(/:([a-z_]+)/) { |m| $1 && $1.size > 0 && context[$1.to_sym] }; string
  end
end