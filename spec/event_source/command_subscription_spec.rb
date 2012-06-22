describe 'event source command subscription' do
  context 'with a valid event source definition' do
    context 'a single command subscription is defined' do
      class ESCD1
        include Euston::MessageSource

        commands

        buy_milk do; end
      end

      let(:metadata)  { ESCD1.message_map.to_hash }

      describe 'command metadata' do
        subject { metadata[:commands] }

        it                { should be_a Hash }
        its([:buy_milk])  { should be_a Hash }

        describe 'the buy_milk definition' do
          subject { metadata[:commands][:buy_milk] }

          its([1]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:commands][:buy_milk][1] }

            its([:identifier])    { should == :id }
            its([:message_type])  { should == :command }
            its([:message_class]) { should == 'BuyMilk_v1' }
          end
        end
      end
    end

    context 'a single command subscription is defined for a specific version' do
      class ESCD2
        include Euston::MessageSource

        commands

        buy_milk 2 do; end
      end

      let(:metadata)  { ESCD2.message_map.to_hash }

      describe 'command metadata' do
        subject { metadata[:commands] }

        it                { should be_a Hash }
        its([:buy_milk])  { should be_a Hash }

        describe 'the buy_milk definition' do
          subject { metadata[:commands][:buy_milk] }

          its([1]) { should be_nil }
          its([2]) { should be_a Hash }

          describe 'version 2' do
            subject { metadata[:commands][:buy_milk][2] }

            its([:identifier])    { should == :id }
            its([:message_type])  { should == :command }
            its([:message_class]) { should == 'BuyMilk_v2' }
          end
        end
      end
    end

    context 'a single command subscription is defined for a specific version with an assigned identifier' do
      class ESCD3
        include Euston::MessageSource

        commands

        buy_milk 2, :xyz do; end
      end

      let(:metadata)  { ESCD3.message_map.to_hash }

      describe 'command metadata' do
        subject { metadata[:commands] }

        it                { should be_a Hash }
        its([:buy_milk])  { should be_a Hash }

        describe 'the buy_milk definition' do
          subject { metadata[:commands][:buy_milk] }

          its([2]) { should be_a Hash }

          describe 'version 2' do
            subject { metadata[:commands][:buy_milk][2] }

            its([:identifier])    { should == :xyz }
            its([:message_type])  { should == :command }
            its([:message_class]) { should == 'BuyMilk_v2' }
          end
        end
      end
    end

    context 'a single command subscription is defined for with an assigned identifier' do
      class ESCD4
        include Euston::MessageSource

        commands

        buy_milk :abc do; end
      end

      let(:metadata)  { ESCD4.message_map.to_hash }

      describe 'command metadata' do
        subject { metadata[:commands] }

        it                { should be_a Hash }
        its([:buy_milk])  { should be_a Hash }

        describe 'the buy_milk definition' do
          subject { metadata[:commands][:buy_milk] }

          its([1]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:commands][:buy_milk][1] }

            its([:identifier])    { should == :abc }
            its([:message_type])  { should == :command }
            its([:message_class]) { should == 'BuyMilk_v1' }
          end
        end
      end
    end

    context 'multiple command subscriptions are defined with varying settings' do
      class ESCD5
        include Euston::MessageSource

        commands

        buy_milk do; end
        walk_dog 2, :abc do; end
        read_paper :xyz do; end
        read_paper 2 do; end
      end

      let(:metadata)  { ESCD5.message_map.to_hash }

      describe 'command metadata' do
        subject { metadata[:commands] }

        it                  { should be_a Hash }
        its([:buy_milk])    { should be_a Hash }
        its([:walk_dog])    { should be_a Hash }
        its([:read_paper])  { should be_a Hash }

        describe 'the buy_milk definition' do
          subject { metadata[:commands][:buy_milk] }

          its([1]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:commands][:buy_milk][1] }

            its([:identifier])    { should == :id }
            its([:message_type])  { should == :command }
            its([:message_class]) { should == 'BuyMilk_v1' }
          end
        end

        describe 'the walk_dog definition' do
          subject { metadata[:commands][:walk_dog] }

          its([2]) { should be_a Hash }

          describe 'version 2' do
            subject { metadata[:commands][:walk_dog][2] }

            its([:identifier])    { should == :abc }
            its([:message_type])  { should == :command }
            its([:message_class]) { should == 'WalkDog_v2' }
          end
        end

        describe 'the read_paper definition' do
          subject { metadata[:commands][:read_paper] }

          its([1]) { should be_a Hash }
          its([2]) { should be_a Hash }

          describe 'version 1' do
            subject { metadata[:commands][:read_paper][1] }

            its([:identifier])    { should == :xyz }
            its([:message_type])  { should == :command }
            its([:message_class]) { should == 'ReadPaper_v1' }
          end

          describe 'version 2' do
            subject { metadata[:commands][:read_paper][2] }

            its([:identifier])    { should == :id }
            its([:message_type])  { should == :command }
            its([:message_class]) { should == 'ReadPaper_v2' }
          end
        end
      end
    end
  end

  context 'with invalid an event source' do
    context 'the same command subscription version is defined twice' do
      let(:exceptions) { [] }

      before do
        begin
          class NaughtyCD1
            include Euston::MessageSource

            commands

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
