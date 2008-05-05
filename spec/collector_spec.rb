require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, "Simple collector" do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :list, :init => [], :collect => :item
      end
      @foo = Foo do
        item "Hello"
        item "World"
      end
    end
    after :each do
      remove_ivars :foo
    end
    
    it "should define a collector method :item" do
      @foo.methods.map{ |x| x.to_sym }.include?(:item).should_be true
    end
    
    it "should collect items into attribute :list" do
      @foo.list.should_be ["Hello", "World"]
    end

  end
end

describe Doodle, "Typed collector with default collector name" do
  temporary_constant :Event, :Location do
    before :each do
      class Location < Doodle
        has :name, :kind => String
      end
      class Event < Doodle
        has :locations, :init => [], :collect => Location
      end
      @event = Event do
        location "Stage 1"
        # todo: move this into spec
        # should handle collected arguments with block only
        location do
          name "Stage 2"
        end
      end
    end
    after :each do
      remove_ivars :event
    end
    
    it "should define a collector method :location" do
      @event.methods.map{ |x| x.to_sym }.include?(:location).should_be true
    end
    
    it "should collect items into attribute :list" do
      @event.locations.map{|loc| loc.name}.should_be ["Stage 1", "Stage 2"]
    end

  end
end

describe Doodle, "Typed collector with specified collector name" do
  temporary_constant :Location, :Event do
    before :each do
      class Location < Doodle
        has :name, :kind => String
      end
      class Event < Doodle
        has :locations, :init => [], :collect => { :place => :Location }
      end
    end
    it "should define a collector method :place" do
      Event.instance_methods.map{ |x| x.to_sym}.include?(:place).should_be true
    end
  end
end

describe Doodle, "typed collector with specified collector name" do
  temporary_constant :Location, :Event do
    before :each do
      class Location < Doodle
        has :name, :kind => String
      end
      class Event < Doodle
        has :locations, :init => [], :collect => { :place => Location }
      end
    end
    it "should collect items into attribute :list" do
      event = nil
      proc {
        event = Event do
          place "Stage 1"
          place "Stage 2"
        end
      }.should_not raise_error
      event.locations.map{|loc| loc.name}.should_be ["Stage 1", "Stage 2"]
      event.locations.map{|loc| loc.class}.should_be [Location, Location]
    end
  end
end

describe Doodle, "typed collector with specified collector name initialized from hash (with default :init param)" do
  temporary_constant :Location, :Event do
    before :each do
      class Location < Doodle
        has :name, :kind => String
        has :events, :collect => :Event
      end
      class Event < Doodle
        has :name, :kind => String
        has :locations, :collect => :Location
      end
    end
    it "should collect items from hash" do
      event = nil
      data = {
        :name => 'RAR',
        :locations =>
        [
         { :name => "Stage 1", :events =>
           [
            { :name => 'Foobars',
              :locations =>
              [ { :name => 'Backstage' } ] } ] }, { :name => "Stage 2" } ] }
      # note: wierd formatting above simply to pass coverage
      proc {
        event = Event(data)
      }.should_not raise_error
      event.locations.map{|loc| loc.name}.should_be ["Stage 1", "Stage 2"]
      event.locations.map{|loc| loc.class}.should_be [Location, Location]
      event.locations[0].events[0].kind_of?(Event).should_be true
    end
  end
end

describe Doodle, "Simple keyed collector" do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :list, :collect => :item, :key => :size
      end
      @foo = Foo do
        item "Hello"
        item "World"
      end
    end
    after :each do
      remove_ivars :foo
    end
    
    it "should define a collector method :item" do
      @foo.methods.map{ |x| x.to_sym }.include?(:item).should_be true
    end
    
    it "should collect items into attribute :list" do
      @foo.list.should_be( { 5 => "World" } )
    end

  end
end

describe Doodle, "Simple keyed collector #2" do
  temporary_constant :Foo, :Item do
    before :each do
      class Item < Doodle
        has :name
      end
      class Foo < Doodle
        has :list, :collect => Item, :key => :name
      end
    end
    
    it "should define a collector method :item" do
      foo = Foo.new
      foo.methods.map{ |x| x.to_sym }.include?(:item).should_be true
      foo.respond_to?(:item).should_be true
    end
    
    it "should collect items into attribute :list #1" do
      foo = Foo do
        item "Hello"
        item "World"
      end
      foo.list.to_a.map{ |k, v| [k, v.class, v.name] }.should_be( [["Hello", Item, "Hello"], ["World", Item, "World"]] )
    end

    it "should collect keyword argument enumerable into attribute :list" do
      foo = Foo(:list =>
                [
                 { :name => "Hello" },
                 { :name => "World" }
                ]
                )
      foo.list.to_a.map{ |k, v| [k, v.class, v.name] }.should_be( [["Hello", Item, "Hello"], ["World", Item, "World"]] )
    end
    
    it "should collect positional argument enumerable into attribute :list" do
      foo = Foo([
                { :name => "Hello" },
                { :name => "World" }
                ]
                )
      foo.list.to_a.map{ |k, v| [k, v.class, v.name] }.should_be( [["Hello", Item, "Hello"], ["World", Item, "World"]] )
    end
    
  end
end
