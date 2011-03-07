require 'webrat/core/matchers/have_selector'
require 'webrat/core/matchers/have_content'
require 'nokogiri'

begin
  require 'builder'
rescue LoadError => e
end


# This class is useful for making sure an HTML text has certain tags/content
# It supports both XML and HTML.  For example, if you want to make sure someone has included
# a link that points to google, has no follow, with the text 'Google Sucks!':
# c = Checker.new(html) do |v|
#   v.matches('a', :href => "http://google.com", :rel => "nofollow", :content => "Google Sucks!")
# end
# 
# c.success? == true # if html does include the link to google
# c.errors == [] # errors is a list of error messages for each match that did not succeed, which can be customized:
#
# c = Checker.new(html) do |v|
#   v.matches('a', :href => "http://google.com", :rel => "nofollow", :content => "Google Sucks!").failure_message('Sorry, no google link, should have :tag')
# end
#
# c.errors
#=> ["Sorry, no google link, should have <a href='http://google.com' rel='nofollow'>Google Sucks!</a>"]
#
# You can also nest matches, to match against children content.  For example, if you
# want check for an image link:
#
# c = Checker.new(html) do |v|
#   v.matches('a', :href => "http://google.com", :rel => "nofollow", :content => "Google Sucks!") do |a|
#     a.matches('img', :src => 'http://google.com/sucks.png')
#   end
# end
#
# which will succeed only if the img tag is nested below the a tag.  You can nest matchers pretty deep
#
#

unless defined?(BasicObject)
  if defined?(Builder::BlankSlate)
    BasicObject = Builder::BlankSlate
  else
    raise 'Azebiki only supported on 1.8.7 when used in a rails application, otherwise, use 1.9.2'
  end
end

module Azebiki
  class Checker
    
    class MyHaveSelector < Webrat::Matchers::HaveSelector
      def tag_inspect
        options = @options.dup
        count = options.delete(:count)
        content = options.delete(:content) unless @expected == "meta"

        html = "<#{@expected}"
        options.each do |k,v|
          html << " #{k}='#{v}'"
        end

        html << ">#{content}</#{@expected}>"

        html
      end
      
      def add_attributes_conditions_to(query)
        attribute_conditions = []

        @options.each do |key, value|
          next if key == :content unless @expected == "meta"
          next if key == :count
          if value.is_a?(Hash)
            func, match = value.keys.first, value.values.first
            attribute_conditions << "#{func}(@#{key}, #{xpath_escape(match)})"
          else
            attribute_conditions << "@#{key} = #{xpath_escape(value)}"
          end
        end
        
        if attribute_conditions.any?
          query << "[#{attribute_conditions.join(' and ')}]"
        end
      end
      
      def add_content_condition_to(query)
        if @options[:content] and @expected != "meta"
          query << "[contains(., #{xpath_escape(@options[:content])})]"
        end
      end

      def matches?(stringlike, &block)
        @block ||= block
        matched = matches(stringlike)

        if @options[:count]
          matched.size == @options[:count] && (!@block || @block.call(matched))
        else
          matched.any? && (!@block || @block.call(matched))
        end
      end


    end
    
    class MatcherProxy
      
      def initialize(have_matcher)
        @have_matcher = have_matcher
        @failure_message = "Content should have included #{content_message}, but did not"
      end
      
      def failure_message(new_failure_message)
        @failure_message = new_failure_message.gsub(/:tag/, content_message)
      end
      
      def content_message
        if @have_matcher.respond_to?(:tag_inspect)
          @have_matcher.tag_inspect
        else
          @have_matcher.content_message
        end
      end
      
      def matches?(content)
        @have_matcher.matches?(content)
      end
      
      def message
        @failure_message
      end
      
    end

    class MatcherBuilder < BasicObject

      attr_reader :tags, :contents, :failure_message
      
      def initialize(&block)
        @tags = []
        @contents = []
        instance_eval &block
      end
      
      def has_content(text)
        @contents << text
      end

      # special case for BlankSlate
      def p(*args, &block)
        handle_tag(:p, *args, &block)
      end

      def method_missing(method, *args, &block)
        handle_tag(method, *args, &block)
      end

      private

      def handle_tag(method, *args, &block)
        tag = {:tag_name => method.to_s}
        
        if args.first.is_a?(::String)
          id_or_class = args.first
          
          if id_or_class.split('#').size == 2
            id_and_classes = id_or_class.split('#').last
            id_and_classes = id_and_classes.split('.')
            tag[:id] = id_and_classes.shift
            tag[:class] = id_and_classes
          end

        elsif args.first.is_a?(::Hash)
          tag.merge!(args.first)
        end

        if args[1] && args[1].is_a?(::Hash)
          if classes = args[1][:class]
            tag[:class] ||= []
            classes.split('.').reject {|s| s.empty? }.each do |s|
              tag[:class] << s
            end

            tag[:class].uniq!
          end

          tag.merge!(args[1])
        end
        
        if tag[:class]
          tag[:class] = tag[:class].join(' ')
          tag.delete(:class) if tag[:class].strip.empty?
        end
        
        tag[:child] = block
  
        @tags << tag

        def tag.failure_message(text)
          self[:failure_message] = text
        end

        return tag
      end

    end
    
    attr_accessor :content, :have_matchers, :errors
    
    def initialize(content, &block)
      @content = content
      @errors = []
      @have_matchers = []
      @self_before_instance_eval = eval "self", block.binding
      @matcher_builder = MatcherBuilder.new(&block)
      build_contents
      build_matchers
      run_matchers
    end
    
    def contains(matching_text)
      selector = MatcherProxy.new(Webrat::Matchers::HasContent.new(matching_text))
      @have_matchers << selector
      selector
    end

    
    def matches(name, attributes = {}, &block)
      if block_given?
        
        have = MyHaveSelector.new(name, attributes) do |n|
          Azebiki::Checker.new(n, &block).success?
        end
        
        selector = MatcherProxy.new(have)
      else
        selector = MatcherProxy.new(MyHaveSelector.new(name, attributes))
      end
      
      @have_matchers << selector
      selector
    end
    
    def success?
      @success
    end
    
    private

    def build_contents
      @matcher_builder.contents.each do |s|
        contains s
      end
    end
    
    def method_missing(method, *args, &block)
      @self_before_instance_eval.send method, *args, &block
    end
    
    def build_matchers
      @matcher_builder.tags.each do |tag|
        name = tag.delete(:tag_name)
        b = tag.delete(:child)
        attributes = tag
        selector = matches(name, attributes, &b) 
        if tag[:failure_message]
          selector.failure_message(tag[:failure_message])
        end
      end
    end

    def run_matchers
      return true if @have_matchers.empty?
      @have_matchers.each do |selector|
        if !selector.matches?(@content)
          @errors << selector.message
        end
      end

      @success = @errors.empty?
    end
    
  end
end
