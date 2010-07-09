module ModelFormatting
  module InstanceMethods
  protected
    def format_content_with_model_formatting
      self.class.model_formatting_attributes.each do |original, formatted|
        text = send(original)
        data = \
          if text.blank?
            ''
          else
            options = {:white_list => model_formatting_white_list,
                       :before => model_formatting_before_callback,
                       :after => model_formatting_after_callback}
            model_formatting_context.inject(options) do |o, attribute|
              o.update attribute => send(attribute)
            end
            ModelFormatting.process(:html, text, options)
          end
          
        send("#{formatted}=", data)
      end
    end
  end
end