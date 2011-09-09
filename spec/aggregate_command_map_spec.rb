
require File.expand_path("../spec_helper", __FILE__)

module Cqrs

  describe "AggregateCommandMap" do
    let(:guid1) {Cqrs.uuid.generate}
    let(:guid2) {Cqrs.uuid.generate}

    let(:command_cw) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :create_widget, 1),
                      :body => { :id => guid1} } }
    let(:command_iw) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :import_widget, 1),
                      :body => { :id => guid1, :imported_count => 5 } } }
    let(:command_aw) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :log_access_to_widget, 1),
                      :body => { :widget_id => guid1 } } }
    let(:command_cp) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :create_product, 1),
                      :body => { :id => guid2} } }
    let(:command_ip) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :import_product, 1),
                      :body => { :id => guid2, :imported_count => 5 } } }
    let(:command_ap) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :log_access_to_product, 1),
                      :body => { :product_id => guid2 } } }

    describe "when creating new Aggregates" do
      let(:aggregate) { Cqrs::Sample::Widget.new( Cqrs.uuid.generate ) }
      let(:aggregate2) { Cqrs::Sample::Product.new( Cqrs.uuid.generate ) }

      it "then side effects are seen" do

        aggregate.committed_commands.should have(0).items
        aggregate2.committed_commands.should have(0).items

        Cqrs::Sample::Widget.new( Cqrs.uuid.generate )

        AggregateCommandMap.map.should have(2).items

        #ap AggregateCommandMap.map

        entry1 = AggregateCommandMap.map[0]
        entry1[:type].should eql(Cqrs::Sample::Widget)
        entry1[:mappings].should have(3).items

        entry2 = AggregateCommandMap.map[1]
        entry2[:type].should eql(Cqrs::Sample::Product)
        entry2[:mappings].should have(3).items

      end
    end

    describe "when consuming commands with first constructor" do
      it "is followed by a consumes command" do

        results = {}
        Repository.stub(:find) do |type, id|
          results[id]
        end

        aggregate = AggregateCommandMap.deliver_command command_cw[:headers], command_cw[:body]
        results[aggregate.aggregate_id] = aggregate
        aggregate.uncommitted_events.should have(1).item

        aggregate2 = AggregateCommandMap.deliver_command command_aw[:headers], command_aw[:body]
        aggregate2.uncommitted_events.should have(2).items

      end
    end

    describe "when consuming commands with the second constructor" do
      it "is followed by a consumes command" do

        results = {}
        Repository.stub(:find) do |type, id|
          results[id]
        end

        aggregate = AggregateCommandMap.deliver_command command_iw[:headers], command_iw[:body]
        results[aggregate.aggregate_id] = aggregate
        aggregate.uncommitted_events.should have(1).item

        aggregate2 = AggregateCommandMap.deliver_command command_aw[:headers], command_aw[:body]
        aggregate2.uncommitted_events.should have(2).items
      end
    end

    describe "when consuming commands with the two constructs" do
      it "is followed by a consumes command" do

        results = {}
        Repository.stub(:find) do |type, id|
          results[id]
        end

        aggregate = AggregateCommandMap.deliver_command command_iw[:headers], command_iw[:body]
        results[aggregate.aggregate_id] = aggregate
        aggregate.uncommitted_events.should have(1).item
        AggregateCommandMap.deliver_command command_iw[:headers], command_iw[:body]
        AggregateCommandMap.deliver_command command_aw[:headers], command_aw[:body]
        aggregate.uncommitted_events.should have(3).items
        ap aggregate.uncommitted_events
      end
    end
  end

end
