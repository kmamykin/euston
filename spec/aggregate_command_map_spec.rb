
require File.expand_path("../spec_helper", __FILE__)

module Cqrs

  describe "AggregateCommandMap" do
    let(:aggregate) { Cqrs::Sample::Widget.new( Cqrs.uuid.generate ) }
    let(:aggregate2) { Cqrs::Sample::Product.new( Cqrs.uuid.generate ) }

    let(:command_cw) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :create_widget, 1),
                      :body => { :id => aggregate.aggregate_id} } }
    let(:command_iw) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :import_widget, 1),
                      :body => { :id => aggregate.aggregate_id, :imported_count => 5 } } }
    let(:command_aw) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :log_access_to_widget, 1),
                      :body => { :widget_id => aggregate.aggregate_id } } }
    let(:command_cp) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :create_product, 1),
                      :body => { :id => aggregate2.aggregate_id} } }
    let(:command_ip) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :import_product, 1),
                      :body => { :id => aggregate2.aggregate_id, :imported_count => 5 } } }
    let(:command_ap) { { :headers => Cqrs::CommandHeaders.new(Cqrs.uuid.generate, :log_access_to_product, 1),
                      :body => { :product_id => aggregate2.aggregate_id } } }
    before do
      aggregate
      aggregate2
    end

    describe "when creating new Aggregates" do
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

        AggregateCommandMap.map.should have(2).items
        aggregate.committed_commands.should have(0).items
        aggregate2.committed_commands.should have(0).items

        aggregate.consume_command command_cw[:headers], command_cw[:body]

        aggregate.uncommitted_events.should have(1).item

        aggregate.consume_command command_aw[:headers], command_aw[:body]

        aggregate.uncommitted_events.should have(2).items

      end
    end

    describe "when consuming commands with the second constructor" do
      it "is followed by a consumes command" do

        AggregateCommandMap.map.should have(2).items
        aggregate.committed_commands.should have(0).items
        aggregate2.committed_commands.should have(0).items

        aggregate.consume_command command_iw[:headers], command_iw[:body]

        aggregate.uncommitted_events.should have(1).item

        aggregate.consume_command command_aw[:headers], command_aw[:body]

        aggregate.uncommitted_events.should have(2).items

      end
    end
  end

end
