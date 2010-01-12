module ModelFormatting::Init
  def self.setup_on(base)
    base.extend self
  end

  # class Foo < ActiveRecord::Base
  #   formats :body => :formatted_body do
  #     # add more attributes
  #     attributes[:title] = :full_title
  #
  #     # add model methods to add to the processing context
  #     context << :project_id
  #
  #     # modify the sanitizer
  #     white_list.allowed_tags << 'form'
  #     white_list.allowed_attributes << 'class'
  #
  #     # add a callback for before html/markdown is processed
  #     before do |format, text, options|
  #
  #     end
  #
  #     # add a callback for after html/markdown is processed
  #     after do |format, text, options|
  #
  #     end
  #   end
  # end
  #
  def formats(*args, &block)
    unless respond_to?(:model_formatting_attributes)
      # use all these attributes instead of a single ModelFormatting::Config because
      # it's easier to support subclassing.
      class_inheritable_accessor :model_formatting_attributes, 
        :model_formatting_white_list, :model_formatting_context, 
        :model_formatting_before_callback, :model_formatting_after_callback
      send :include, ModelFormatting::InstanceMethods
      self.model_formatting_context    = []
      self.model_formatting_attributes = {} 
      self.model_formatting_white_list = HTML::WhiteListSanitizer.new
      before_save :format_content_with_model_formatting
    end

    model_formatting_attributes.update args.extract_options!
    args.each do |field|
      model_formatting_attributes[field] = "formatted_#{field}"
    end

    if block
      config = ModelFormatting::Config.new(model_formatting_white_list, model_formatting_attributes, model_formatting_context)
      config.instance_eval &block
      self.model_formatting_before_callback = config.before_callback if config.before_callback
      self.model_formatting_after_callback  = config.after_callback  if config.after_callback
    end
  end
end