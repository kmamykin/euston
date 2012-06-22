describe 'event source transition definition' do
  context 'with a valid event source definition' do
    context 'a single state transition is defined' do
      class ESTD1
        include Euston::MessageSource

        transitions

        milk_bought do; end
      end

      let(:metadata)  { ESTD1.message_map.to_hash }

      describe 'transition metadata' do
        subject { metadata[:transitions] }

        it                  { should be_a Hash }
        its([:milk_bought]) { should be_a Hash }

        describe 'the milk_bought definition' do
          subject { metadata[:transitions][:milk_bought] }

          its([1]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:transitions][:milk_bought][1] }

            its([:identifier])    { should be_nil }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'MilkBought_v1' }
          end
        end
      end
    end

    context 'a single state transition is defined for a specific version' do
      class ESTD2
        include Euston::MessageSource

        transitions

        milk_bought 2 do; end
      end

      let(:metadata)  { ESTD2.message_map.to_hash }

      describe 'transition metadata' do
        subject { metadata[:transitions] }

        it                  { should be_a Hash }
        its([:milk_bought]) { should be_a Hash }

        describe 'the milk_bought definition' do
          subject { metadata[:transitions][:milk_bought] }

          its([1]) { should be_nil }
          its([2]) { should be_a Hash }

          describe 'version 2' do
            subject { metadata[:transitions][:milk_bought][2] }

            its([:identifier])    { should be_nil }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'MilkBought_v2' }
          end
        end
      end
    end

    context 'multiple state transitions are defined' do
      class ESTD3
        include Euston::MessageSource

        transitions

        milk_bought do; end
        dog_walked 2 do; end
        paper_read do; end
        paper_read 2 do; end
      end

      let(:metadata)  { ESTD3.message_map.to_hash }

      describe 'transition metadata' do
        subject { metadata[:transitions] }

        it                  { should be_a Hash }
        its([:milk_bought]) { should be_a Hash }
        its([:dog_walked])  { should be_a Hash }
        its([:paper_read])  { should be_a Hash }

        describe 'the milk_bought definition' do
          subject { metadata[:transitions][:milk_bought] }

          its([1]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:transitions][:milk_bought][1] }

            its([:identifier])    { should be_nil }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'MilkBought_v1' }
          end
        end

        describe 'the dog_walked definition' do
          subject { metadata[:transitions][:dog_walked] }

          its([2]) { should be_a Hash }

          describe 'version 2' do
            subject { metadata[:transitions][:dog_walked][2] }

            its([:identifier])    { should be_nil }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'DogWalked_v2' }
          end
        end

        describe 'the paper_read definition' do
          subject { metadata[:transitions][:paper_read] }

          its([1]) { should be_a Hash }
          its([2]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:transitions][:paper_read][1] }

            its([:identifier])    { should be_nil }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'PaperRead_v1' }
          end

          describe 'version 2' do
            subject { metadata[:transitions][:paper_read][2] }

            its([:identifier])    { should be_nil }
            its([:message_type])  { should == :event }
            its([:message_class]) { should == 'PaperRead_v2' }
          end
        end
      end
    end
  end
end
