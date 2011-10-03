require File.expand_path("../spec_helper", __FILE__)

module Euston

  describe "AggregateCommandMap" do
    let(:guid1) {Euston.uuid.generate}
    let(:guid2) {Euston.uuid.generate}

    let(:command_cw) { { :headers => CommandHeaders.new(Euston.uuid.generate, :create_widget, 1),
                      :body => { :id => guid1} } }
    let(:command_iw) { { :headers => CommandHeaders.new(Euston.uuid.generate, :import_widget, 1),
                      :body => { :id => guid1, :imported_count => 5 } } }
    let(:command_aw) { { :headers => CommandHeaders.new(Euston.uuid.generate, :log_access_to_widget, 1),
                      :body => { :widget_id => guid1 } } }
    let(:command_cp) { { :headers => CommandHeaders.new(Euston.uuid.generate, :create_product, 1),
                      :body => { :id => guid2} } }
    let(:command_ip) { { :headers => CommandHeaders.new(Euston.uuid.generate, :import_product, 1),
                      :body => { :id => guid2, :imported_count => 5 } } }
    let(:command_ap) { { :headers => CommandHeaders.new(Euston.uuid.generate, :log_access_to_product, 1),
                      :body => { :product_id => guid2 } } }

    describe "when creating new Aggregates" do
      let(:aggregate) { Sample::Widget.new( Euston.uuid.generate ) }
      let(:aggregate2) { Sample::Product.new( Euston.uuid.generate ) }

      it "then side effects are seen" do

        aggregate.committed_messages.should have(0).items
        aggregate2.committed_messages.should have(0).items

        Sample::Widget.new( Euston.uuid.generate )

        AggregateCommandMap.map.should have(2).items

        #ap AggregateCommandMap.map

        entry1 = AggregateCommandMap.map[0]
        entry1[:type].should eql(Euston::Sample::Widget)
        entry1[:mappings].should have(3).items

        entry2 = AggregateCommandMap.map[1]
        entry2[:type].should eql(Euston::Sample::Product)
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
      end
    end
  end

end
