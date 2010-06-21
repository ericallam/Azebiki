## Overview

Azebiki provides a simple dsl for declaring CSS and XPATH matchers against a block of HTML content.  It is built on top of Webrat matchers and nokogiri.

## Example:

Given this block of HTML:

    <html>
    <head><title>Example</title></head>
    <body>
    <!--
    <a href="http://incomment.com">In Comment</a>
    -->
    <div id='main' class="big">
      <p id="body">
        <table class='short table'>
          <thead>
            <tr>
              <th>First Column</th>
            </tr>
          </thead>
        </table>
      </p>
    </div>

Given this Azebiki::Checker definition:

    c = Azebiki::Checker.new(HTML) do
      div('#main.big') do
        p('#body') do
          table do
            thead do
              tr do
                th(:content => 'First Column')
              end
            end
          end
        end
      end
    end

Will result in:

    c.success?
    # => true

Or given this definition:

    c = Azebiki::Checker.new(HTML) do
      a(:href => 'http://incomment.com', :content => 'In Comment')
    end

Will result in:

    c.success?
    # => false
    c.errors.inspect
    # => ['Content should have included <a href="http://incomment.com">In Comment</a>, but did not']

Or give it a custom error message:

    c = Azebiki::Checker.new(HTML) do
      a(:href => 'http://incomment.com', :content => 'In Comment').failure_message('No tag :tag, SORRY!')
    end

    c.errors.inspect
    # => ['No tag <a href="http://incomment.com">In Comment</a>, SORRY!']
            

## Install

gem install azebiki


