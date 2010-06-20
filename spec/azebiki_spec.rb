require "spec_helper"

describe Azebiki::Checker do  
  
  def body
<<-HTML
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>
      testing auto payout new rejection - the affiliate of your nightmares
    </title>
    <link rel="alternate" type="application/rss+xml" title="RSS" href="http://imakemoremoneythangod.tumblr.com/rss" />
  </head>
  <body>
    Will somebody please find me?
    <div id="content">
      <h1>
        <a id="toplink" href="http://google.com?hello=world&amp;something=1">the affiliate of your nightmares</a>
      </h1>
      <div id="description">
        <div>
          <div id="search">
            <form action="/search" method="get">
              <input type="text" name="q" value="" /> <input type="submit" value="Search" />
            </form>
          </div><script name="a325e284-c8a4-11de-9917-0017f2c672a5" src="http://localhost:5000/itk/show/imakemoremoneythangod-tumblr-com" type="text/javascript">
</script>
          <p id="nav_container">
            <!-- <a href="/archive" id="archive_link" name="archive_link">Archive</a> <span class="dim">/</span> <a href="http://imakemoremoneythangod.tumblr.com/rss">RSS</a> -->
          </p>
        </div>
      </div>
      <div class="post">
        <div class="regular">
          <p>
            <a href="http://localhost:9292/metrics/click/post?slot_id=25709&amp;url=http%3A%2F%2Fgooglasdsade.com" rel="asdasnofollow">aklshjdkasd</a>
          </p>
          <p>
            <map name="map2480" id="map2480">
              <area href="http://localhost:9292/metrics/click" shape="rect" coords="0,0,206,45" rel="nofollow" />
              <br />
              <area href="http://localhost:3000/code_of_ethics" shape="rect" coords="207,0,225,45" rel="nofollow" />
            </map><img alt="disclosure_badge_grey" border="0" src="http://localhost:9292/metrics/view/post" style="border:0" usemap="#map2480" />
          </p>
        </div>
      </div>
    </div>
  </body>
</html>
HTML
  end
  
  describe "contains" do
    it "should return true if the text is found in the html" do
      c = Azebiki::Checker.new(body) do
        contains('Will somebody please find me?')
      end
      
      c.should be_success
    end
    
    it "should return false if the text is not in the html" do
      c = Azebiki::Checker.new(body) do
        contains('This it not be in the html')
      end
      
      c.should_not be_success
    end
  end # contains
  
  it "should allow a block to match child elements" do
    c = Azebiki::Checker.new(body) do
      matches('map', :id => 'map2480') do
        matches('area', :href => "http://localhost:9292/metrics/click")
      end
    end
    
    c.should be_success
  end
  
  it "should allow wildcard matchs" do
    c = Azebiki::Checker.new(body) do
      matches('map', :id => {'starts-with' => 'map'})
    end
    
    c.should be_success
  end
  
  it "should allow wildcard matches for content" do
    c = Azebiki::Checker.new(body) do
      matches('a', :id => 'toplink', :content => "nightmares")
    end
    
    c.should be_success
  end
  
  it "should allow a multiple child matches" do
    c = Azebiki::Checker.new(body) do
      matches('map', :id => 'map2480') do
        matches('area', :href => "http://localhost:9292/metrics/click")
        matches('area', :href => "http://localhost:3000/code_of_ethics")
      end
    end
    
    c.should be_success
  end
  
  it "should allow a multiple nested matches" do
    c = Azebiki::Checker.new(body) do |v|
      
      matches('map', :id => 'map2480') do
        matches('area', :href => "http://localhost:9292/metrics/click")
      end
      
      matches('form') do
        matches('input', :name => "q")
      end
      
    end
    
    c.should be_success
  end
  
  it "should not be a success if child does not match" do
    c = Azebiki::Checker.new(body) do
      matches('map', :id => 'map2480') do
        matches('area', :href => "http://localhost:9292/nowayjose")
      end
    end
    
    c.should_not be_success

    c.errors.size.should == 1
  end
  
  it "should not match a parent in the child block" do
    c = Azebiki::Checker.new(body) do
      matches('map', :id => 'map2480') do
        matches('div', :class => "post")
      end
    end
    
    c.should_not be_success
    c.errors.size.should == 1
  end
  
  it "should be a success if everything matches" do
    c = Azebiki::Checker.new(body) do
      matches('map')
    end
    
    c.should be_success
  end
  
  it "should not be a success if one thing does not match" do
    c = Azebiki::Checker.new(body) do
      matches('h6')
    end
    
    c.should_not be_success
  end
  
  it "should match on attributes also" do
    c = Azebiki::Checker.new(body) do
      matches('map', :name => "map2481")
    end
    
    c.should_not be_success
    
    c = Azebiki::Checker.new(body) do
      matches('map', :name => "map2480")
    end
    
    c.should be_success
  end
  
  it "should match on the content also" do
    c = Azebiki::Checker.new(body) do
      matches('a', :rel => 'asdasnofollow', :content => 'badcontent')
    end
    
    c.success?.should == false
    
    c = Azebiki::Checker.new(body) do
      matches('a', :rel => 'asdasnofollow', :content => 'aklshjdkasd')
    end
    
    c.should be_success
  end
  
  it "should allow multiple matches" do
    c = Azebiki::Checker.new(body) do
      matches('a', :rel => 'asdasnofollow', :content => 'aklshjdkasd')
      matches('map', :name => "map2480")
    end
    
    c.should be_success
  end
  
  it "should not be a success if one of the matches is false" do
    c = Azebiki::Checker.new(body) do
      matches('a', :rel => 'asdasnofollow', :content => 'aklshjdkasd')
      matches('map', :name => "fail")
    end
    
    c.should_not be_success
  end
  
  it "should not match on comments" do
    c = Azebiki::Checker.new(body) do
      matches('a', :content => 'Archive')
    end
    
    c.should_not be_success
  end
  
  it "should match for urls with escaped in them" do
    c = Azebiki::Checker.new(body) do
      matches('a', :id => "toplink", :href => "http://google.com?hello=world&something=1")
    end
    
    c.should be_success
  end
  
  it "should be able to nest more than 1 level deep" do
    c = Azebiki::Checker.new(body) do
      matches('div', :id => "content") do
        matches('div', :class => "post") do
          matches('div', :class => "regular") do
            matches('p') do
              matches('a', :content => "aklshjdkasd")
            end
          end
        end
      end
    end
    
    c.should be_success
  end
  
  describe "errors" do
    
    before do
      @c = Azebiki::Checker.new(body) do
        matches('a', :rel => 'asdasnofollow', :content => 'aklshjdkasd') #success
        matches('map', :name => "fail") #fail with default message
        matches('div', :class => 'noclasshere').failure_message('There is no div with class noclasshere') # fail with custom message
      end
    end
    
    it "should return a list of errors for each match that fails" do
      @c.errors.size.should == 2
    end
    
    it "should allow for custom failure messages" do
      @c.errors.should include('There is no div with class noclasshere')
    end
    
    it "should allow for custom failure messages on matching child elements" do
      c = Azebiki::Checker.new(body) do
        matches('map', :id => 'map2481') do
          matches('area', :href => "http://localhost:9292/metrics/click")
        end.failure_message('There is no map')
      end
      
      c.errors.should include('There is no map')
    end
    
    
  end # errors
  
  
  describe "closure scope" do
    
    it "not raise a NoMethodError because the local var rel should be in the closure scope" do
      rel = 'asdasnofollow'

      lambda {
        Azebiki::Checker.new(body) do
          matches('a', :rel => rel, :content => 'aklshjdkasd') #success
          matches('map', :name => "fail") #fail with default message
          matches('div', :class => 'noclasshere').failure_message('There is no div with class noclasshere') # fail with custom message
        end
      }.should_not raise_error(NameError)
    end
  end
  
  
end
