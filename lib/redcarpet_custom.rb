require 'redcarpet'
module Redcarpet::Render
  class Custom < HTML
    # include Redcarpet::Render::HTML
    def header(title, level)
      @headers ||= []
      # you can use this permalink style: 1-foo-bar with the level in it
      # permalink = "#{level}-#{title.gsub(/\W+/, "-")}"
      
      # .. or just use title. you might like a better regex here, too
      permalink = title.gsub(/\W+/, "-")
      
      # for extra credit: implement this as its own method
      if @headers.include?(permalink)
        permalink += "_1"
         # my brain hurts
        loop do
          break if !@headers.include?(permalink)
          # generate titles like foo-bar_1, foo-bar_2
          permalink.gsub!(/\_(\d+)$/, "_#{$1.to_i + 1}")
        end
      end
      @headers << permalink
      %(\n<a name="#{permalink}" class="anchor" href="##{permalink}"><span class="anchor-icon"></span></a><h#{level} id=\"#{permalink}\">#{title}</h#{level}>\n)
    end
  end
end