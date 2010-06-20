require 'webrat/core/matchers/have_selector'
require 'webrat/core/matchers/have_content'
require 'nokogiri'

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
module Azebiki
  class Checker
    
    class MyHaveSelector < Webrat::Matchers::HaveSelector
      def add_attributes_conditions_to(query)
        attribute_conditions = []

        @options.each do |key, value|
          next if [:content, :count].include?(key)
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
    
    attr_accessor :content, :have_matchers, :errors
    
    def initialize(content, &block)
      @content = content
      @errors = []
      @have_matchers = []
      @self_before_instance_eval = eval "self", block.binding
      instance_eval &block
      run_matches
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
    
    def method_missing(method, *args, &block)
      @self_before_instance_eval.send method, *args, &block
    end
    
    def run_matches
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
