azebiki
=======

Azebiki provides a simple dsl for declaring CSS and XPATH matchers against a block of HTML content.
It is built on top of Webrat matchers and nokogiri.

Usage
-----

Given this block of HTML:

``` html
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
```

Given this Azebiki::Checker definition:

``` ruby
@html = Azebiki::Checker.new HTML do
  div '#main.big' do
    p '#body' do
      table do
        thead do
          tr do
            th content: 'First Column'
          end
        end
      end
    end
  end
end


@html.success?
  # => true
```

Or given this definition:

``` ruby
@html2 = Azebiki::Checker.new HTML do
  a href: 'http://incomment.com', content: 'In Comment'
end

@html2.success?
  # => false

c@html2.errors.inspect
  # => ['Content should have included <a href="http://incomment.com">In Comment</a>, but did not']
```

Or give it a custom error message:

``` ruby
@html3 = Azebiki::Checker.new HTML do
  a(href: 'http://incomment.com', content: 'In Comment').failure_message 'No tag :tag, SORRY!'
end

@html3.errors.inspect
  # => ['No tag <a href="http://incomment.com">In Comment</a>, SORRY!']
```     

Install
-------

Ruby 1.9.x only, 1.8.x not supported.

``` terminal
$ gem install azebiki
```

or

``` ruby
gem 'azebiki', group: :test
```
