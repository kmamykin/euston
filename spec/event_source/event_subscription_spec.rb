describe 'event source event subscription' do
  context 'with a valid event source definition' do
    context 'a single event subscription is defined' do
      class ESED1
        include Euston::MessageSource

        events

        milk_bought do; end
      end

      let(:metadata)  { ESED1.message_map.to_hash }

      describe 'event metadata' do
        subject { metadata[:events] }

        it                  { should be_a Hash }
        its([:milk_bought]) { should be_a Hash }

        describe 'the milk_bought definition' do
          subject { metadata[:events][:milk_bought] }

          its([1]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:events][:milk_bought][1] }

            its([:identifier])    { should be_nil }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'MilkBought_v1' }
          end
        end
      end
    end

    context 'a single event subscription is defined for a specific version' do
      class ESED2
        include Euston::MessageSource

        events

        milk_bought 2 do; end
      end

      let(:metadata)  { ESED2.message_map.to_hash }

      describe 'event metadata' do
        subject { metadata[:events] }

        it                  { should be_a Hash }
        its([:milk_bought]) { should be_a Hash }

        describe 'the milk_bought definition' do
          subject { metadata[:events][:milk_bought] }

          its([1]) { should be_nil }
          its([2]) { should be_a Hash }

          describe 'version 2' do
            subject { metadata[:events][:milk_bought][2] }

            its([:identifier])    { should be_nil }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'MilkBought_v2' }
          end
        end
      end
    end

    context 'a single event subscription is defined for a specific version with an assigned identifier' do
      class ESED3
        include Euston::MessageSource

        events

        milk_bought 2, :xyz do; end
      end

      let(:metadata)  { ESED3.message_map.to_hash }

      describe 'event metadata' do
        subject { metadata[:events] }

        it                  { should be_a Hash }
        its([:milk_bought]) { should be_a Hash }

        describe 'the milk_bought definition' do
          subject { metadata[:events][:milk_bought] }

          its([2]) { should be_a Hash }

          describe 'version 2' do
            subject { metadata[:events][:milk_bought][2] }

            its([:identifier])    { should == :xyz }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'MilkBought_v2' }
          end
        end
      end
    end

    context 'a single event subscription is defined for with an assigned identifier' do
      class ESED4
        include Euston::MessageSource

        events

        milk_bought :abc do; end
      end

      let(:metadata)  { ESED4.message_map.to_hash }

      describe 'event metadata' do
        subject { metadata[:events] }

        it                  { should be_a Hash }
        its([:milk_bought]) { should be_a Hash }

        describe 'the milk_bought definition' do
          subject { metadata[:events][:milk_bought] }

          its([1]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:events][:milk_bought][1] }

            its([:identifier])    { should == :abc }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'MilkBought_v1' }
          end
        end
      end
    end

    context 'multiple event subscriptions are defined with varying settings' do
      class ESED5
        include Euston::MessageSource

        events

        milk_bought do; end
        dog_walked 2, :abc do; end
        paper_read :xyz do; end
        paper_read 2 do; end
      end

      let(:metadata)  { ESED5.message_map.to_hash }

      describe 'event metadata' do
        subject { metadata[:events] }

        it                  { should be_a Hash }
        its([:milk_bought]) { should be_a Hash }
        its([:dog_walked])  { should be_a Hash }
        its([:paper_read])  { should be_a Hash }

        describe 'the milk_bought definition' do
          subject { metadata[:events][:milk_bought] }

          its([1]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:events][:milk_bought][1] }

            its([:identifier])    { should be_nil }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'MilkBought_v1' }
          end
        end

        describe 'the dog_walked definition' do
          subject { metadata[:events][:dog_walked] }

          its([2]) { should be_a Hash }

          describe 'version 2' do
            subject { metadata[:events][:dog_walked][2] }

            its([:identifier])    { should == :abc }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'DogWalked_v2' }
          end
        end

        describe 'the paper_read definition' do
          subject { metadata[:events][:paper_read] }

          its([1]) { should be_a Hash }
          its([2]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:events][:paper_read][1] }

            its([:identifier])    { should == :xyz }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'PaperRead_v1' }
          end

          describe 'version 2' do
            subject { metadata[:events][:paper_read][2] }

            its([:identifier])    { should be_nil }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'PaperRead_v2' }
          end
        end
      end
    end
  end

  context 'with invalid an event source' do
    context 'the same event subscription version is defined twice' do
      let(:exceptions) { [] }

      before do
        begin
          class NaughtyED1
            include Euston::MessageSource

            events

            uh_oh {}
            uh_oh {}
          end
        rescue Euston::SubscriptionRedefinitionError => e
          exceptions << e
        end
      end

      subject { exceptions }

      it { should_not be_empty }
    end
  end
end

