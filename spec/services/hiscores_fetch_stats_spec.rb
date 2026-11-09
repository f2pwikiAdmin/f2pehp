require 'spec_helper'
require 'net/http'
require_relative '../../app/services/base'
require_relative '../../app/services/hiscores'

RSpec.describe Hiscores do
  describe '.fetch_stats' do
    let(:player_name) { 'Test Player' }
    let(:stats) { { 'overall_xp' => 1000 } }
    let(:workers) { Queue.new }

    before do
      allow(described_class).to receive(:api_url) do |mode, _name|
        URI("https://example.com/#{mode}")
      end
      allow(described_class).to receive(:parse_stats_csv).with('csv').and_return(stats)
      allow(described_class).to receive(:fetch) do
        workers << Thread.current
        'csv'
      end
    end

    it 'keeps the existing mode priority when total XP is tied' do
      expect(described_class.fetch_stats(player_name)).to eq([stats, 'UIM'])
    end

    it 'selects the mode with the highest total XP' do
      higher_stats = { 'overall_xp' => 2000 }
      allow(described_class).to receive(:fetch).with(URI('https://example.com/Reg')).and_return('higher')
      allow(described_class).to receive(:parse_stats_csv).with('higher').and_return(higher_stats)

      expect(described_class.fetch_stats(player_name)).to eq([higher_stats, 'Reg'])
    end

    it 'returns nil when no mode has hiscores data' do
      allow(described_class).to receive(:fetch).and_return(nil)

      expect(described_class.fetch_stats(player_name)).to be_nil
    end

    it 'propagates unexpected worker exceptions' do
      allow(described_class).to receive(:fetch).with(URI('https://example.com/UIM')) do
        workers << Thread.current
        raise ArgumentError, 'unexpected failure'
      end

      expect { described_class.fetch_stats(player_name) }
        .to raise_error(ArgumentError, 'unexpected failure')
      expect(workers.size).to eq(4)
      expect(Array.new(4) { workers.pop }).to all(satisfy { |worker| !worker.alive? })
    end

    it 'only fetches regular hiscores for a regular account' do
      expect(described_class).to receive(:fetch).with(URI('https://example.com/Reg')).once

      expect(described_class.fetch_stats(player_name, account_type: 'Reg')).to eq([stats, 'Reg'])
    end

    [Net::ReadTimeout, SocketError].each do |error_class|
      it "raises #{error_class} in the calling thread, not the main thread" do
        error = error_class.new('hiscores unavailable')
        allow(described_class).to receive(:fetch).with(URI('https://example.com/UIM')) do
          workers << Thread.current
          raise error
        end

        caller_thread = Thread.new do
          begin
            described_class.fetch_stats(player_name)
          rescue error_class => e
            e
          end
        end

        expect(caller_thread.value).to equal(error)
        expect(workers.size).to eq(4)
        completed_workers = Array.new(4) { workers.pop }
        expect(completed_workers).to all(satisfy { |worker| !worker.alive? })
      end

      it "does not treat #{error_class} in every mode as a missing player" do
        allow(described_class).to receive(:fetch).and_raise(error_class)

        expect { described_class.fetch_stats(player_name) }.to raise_error(error_class)
      end
    end
  end
end
