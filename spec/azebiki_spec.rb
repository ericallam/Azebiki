require "spec_helper"

describe Azebiki::Checker do  
  
  let(:body) do
    <<-HTML
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
      <head>
        <meta http-equiv="Content-Type" content="something" />
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
                <map name="map2480" id="map2480" class='hello'>
                  <area href="http://google.com" shape="rect" coords="0,0,206,45" rel="nofollow" />
                  <br />
                  <area href="http://google2.com" shape="rect" coords="207,0,225,45" rel="nofollow" />
                </map><img alt="disclosure_badge_grey" border="0" src="http://localhost:9292/metrics/view/post" style="border:0" usemap="#map2480" />
              </p>
            </div>
          </div>
        </div>
        <div id='world'>
          <div id='foo'></div>
        </div>

        <form accept-charset="UTF-8" action="/weapons" class="new_weapon" id="new_weapon" method="post">
          <div style="margin:0;padding:0;display:inline">
            <input name="utf8" type="hidden" value="&#x2713;" />
            <input name="authenticity_token" type="hidden" value="d7hp6Y+g2b9lpeePTkwraLAXy2n3HwlVGt06Oq3jgMc=" />
          </div>
          <select id="weapon_condition" name="weapon[condition]">
            <option value="New">New</option>
            <option value="Rusty">Rusty</option>
            <option value="Broken">Broken</option>
          </select> 
        </form>
      </body>
    </html>
    HTML
  end
  
  describe "contains" do
    it "should return true if the text is found in the html" do
      c = Azebiki::Checker.new(body) do
        has_content "Will somebody please find me?"
      end
      
      c.should be_success
    end
    
    it "should return false if the text is not in the html" do
      c = Azebiki::Checker.new(body) do
         has_content 'This it not be in the html'
      end
      
      c.should_not be_success
    end
  end 
  
  it "should allow wildcard matchs" do
    c = Azebiki::Checker.new(body) do
      map(:id => {'starts-with' => 'map'})
    end
    
    c.should be_success
  end
  
  it "should allow wildcard matches for content" do
    c = Azebiki::Checker.new(body) do
      a('#toplink', :content => "nightmares")
    end
    
    c.should be_success
  end
  
  it "should allow the first argument to be a class like .class" do
    c = Azebiki::Checker.new(body) do
      a('.toplink')
    end
    
    c.should_not be_success
  end
  
  it "should allow a multiple nested matches" do
    c = Azebiki::Checker.new(body) do
      map('#map2480.hello') do
        area(:href => 'http://google.com')
        area(:href => 'http://google2.com')
      end
  
      form do
        input(:name => 'q')
      end
    end
    
    c.should be_success
    
  end
  
  it "should allow three levels of nesting for this form" do
    c = Azebiki::Checker.new(body) do
      form('#new_weapon.new_weapon', action: '/weapons', method: 'post') do
        select('#weapon_condition', name: 'weapon[condition]') do
          option(value: 'New', content: 'New')
          option(value: 'Rusty', content: 'Rusty')
          option(value: 'Broken', content: 'Broken')
        end
      end
    end
    
    c.should be_success
  end
  
  it "should make the third level error bubble up" do
    c = Azebiki::Checker.new(body) do
      form('#new_weapon.new_weapon', action: '/weapons', method: 'post') do
        select('#weapon_condition', name: 'weapon[condition]') do
          option(value: 'Hello', content: 'Hello')
        end
      end
    end
    
    c.errors.should include("Content should have included <option value='Hello'>Hello</option>, but did not")
  end
  
  it "should not be a success if child does not match" do
    c = Azebiki::Checker.new(body) do
      map('#map2480') do
        area(:href => 'http://googlenoooooooo.com')
      end
    end
    
    c.should_not be_success
  
    c.errors.size.should == 1
  end
  
  it "should not match a parent in the child block" do
    c = Azebiki::Checker.new(body) do
      map('#map2480') do
        div('.post')
      end
    end
    
    c.should_not be_success
    c.errors.size.should == 1
  end
  
  it "should be able to match on metas content attribute" do
    c = Azebiki::Checker.new(body) do
      meta(:content => 'something')
    end
    
    c.should be_success
    
    c = Azebiki::Checker.new(body) do
      meta(:content => 'anything')
    end
    
    c.errors.should include("Content should have included <meta content='anything'></meta>, but did not")
  end
  
  it "should match on the content also" do
    c = Azebiki::Checker.new(body) do
      a(:rel => 'asdasnofollow', :content => 'badcontent')
    end
    
    c.success?.should == false
    
    c = Azebiki::Checker.new(body) do
      a(:rel => 'asdasnofollow', :content => 'aklshjdkasd')
    end
    
    c.should be_success
  end
  
  it "should allow multiple matches" do
    c = Azebiki::Checker.new(body) do
      a(:rel => 'asdasnofollow', :content => 'aklshjdkasd')
      map(:name => "map2480")
    end
    
    c.should be_success
  end
  
  it "should not be a success if one of the matches is false" do
    c = Azebiki::Checker.new(body) do
      a(:rel => 'asdasnofollow', :content => 'aklshjdkasd')
      map(:name => "fail")
    end
    
    c.should_not be_success
  end
  
  it "should not match on comments" do
    c = Azebiki::Checker.new(body) do
      a(:content => 'Archive')
    end
    
    c.should_not be_success
  end
  
  it "should match for urls with escaped in them" do
    c = Azebiki::Checker.new(body) do
      a("#toplink", :href => "http://google.com?hello=world&something=1")
    end
    
    c.should be_success
  end
  
  it "should be able to nest more than 1 level deep" do
    c = Azebiki::Checker.new(body) do
      div("#content") do
        div(".post") do
          div(".regular") do
            p do
              a(:content => "aklshjdkasd")
            end
          end
        end
      end
    end
    
    c.should be_success
  end
  
  describe "errors" do
    
    context 'with nested tags' do
      context 'without match' do
        subject {
          Azebiki::Checker.new(body) do
            div("#world") do
              div("#foo").failure_message('No div with class .foo')
            end
          end
        }

        its(:errors) { should be_empty }
      end
      
      context 'with match' do
        subject {
          Azebiki::Checker.new(body) do
            div("#world") do
              div("#hello").failure_message('No div with class .world')
            end
          end
        }

        it "should bubble up child failure messages" do
          subject.errors.should include("No div with class .world")
        end

        it "should only have the lowest error message" do
          subject.errors.size.should == 1
        end
      end

    end
    
    context 'without nested tags' do
      before do
        @c = Azebiki::Checker.new(body) do
          a(:rel => 'asdasnofollow', :content => 'aklshjdkasd') #success
          map(:name => "fail") #fail with default message
          div('#noclasshere').failure_message('There is no div with id noclasshere')
        end
      end

      it "should return a list of errors for each match that fails" do
        @c.errors.size.should == 2
      end

      it "should allow for custom failure messages" do
        @c.errors.should include('There is no div with id noclasshere')
      end

      it "should allow for custom failure messages on matching child elements" do
        c = Azebiki::Checker.new(body) do
          map('#map2481') do
            area(:href => "http://localhost:9292/metrics/click")
          end.failure_message('There is no map')
        end

        c.errors.should include('There is no map')
      end
    end    
    
  end # errors
  
  
  describe "closure scope" do
    
    it "not raise a NoMethodError because the local var rel should be in the closure scope" do
      rel = 'asdasnofollow'
  
      lambda {
        Azebiki::Checker.new(body) do
          a(:rel => rel, :content => 'aklshjdkasd') #success
          map(:name => "fail") #fail with default message
          div('.noclasshere')
        end
      }.should_not raise_error(NameError)
    end
  end
  
  
end
