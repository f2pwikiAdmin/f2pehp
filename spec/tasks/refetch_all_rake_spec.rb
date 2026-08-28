require 'rails_helper'
require 'rake'

RSpec.describe 'players:refetch_all' do
  before(:all) do
    Rake.application = Rake::Application.new
    load Rails.root.join('Rakefile')
    Rake::Task.define_task(:environment)
  end

  after(:all) do
    Rake.application = nil
  end

  let(:task) { Rake::Task['players:refetch_all'] }
  let(:scope) { double('Player scope') }
  let(:count_scope) { double('Count scope') }
  let(:player_one) { double('Player', id: 4, player_name: 'Alpha') }
  let(:player_two) { double('Player', id: 5, player_name: 'Bravo') }
  let(:logger) { instance_double(ActiveSupport::Logger, warn: true) }

  around do |example|
    original_env = ENV.to_hash
    %w[SLEEP START_ID LIMIT PROGRESS].each { |key| ENV.delete(key) }
    example.run
    ENV.replace(original_env)
  end

  before do
    task.reenable

    allow(Player).to receive(:all).and_return(scope)
    allow(scope).to receive(:count).and_return(10)
    allow(scope).to receive(:find_each).with(batch_size: 100).and_yield(player_one).and_yield(player_two)
    allow(player_one).to receive(:update_player)
    allow(player_two).to receive(:update_player).and_raise(StandardError, 'boom')
    allow(Rails).to receive(:logger).and_return(logger)
    allow(Kernel).to receive(:sleep)
  end

  it 'applies START_ID and LIMIT, logs errors, and prints resumable progress output' do
    ENV['START_ID'] = '4'
    ENV['LIMIT'] = '2'
    ENV['SLEEP'] = '0'
    ENV['PROGRESS'] = '1'

    allow(scope).to receive(:where).with('id >= ?', 4).and_return(scope)
    allow(scope).to receive(:limit).with(2).and_return(count_scope)
    allow(count_scope).to receive(:count).and_return(2)

    expect {
      task.invoke
    }.to output(/Total players to process: 2.*\[1\/2\] Processed 1 players \(last id=4\).*\[2\/2\] ✗ Error for Bravo \(ID: 5\): boom.*\[2\/2\] Processed 2 players \(last id=5\).*Errors: 1.*Last id: 5/m).to_stdout

    expect(scope).to have_received(:where).with('id >= ?', 4)
    expect(scope).to have_received(:limit).with(2)
    expect(player_one).to have_received(:update_player)
    expect(player_two).to have_received(:update_player)
    expect(logger).to have_received(:warn).with('refetch_all: failed Bravo (#5): boom')
  end

  it 'counts network failures without halting the run' do
    ENV['SLEEP'] = '0'
    ENV['PROGRESS'] = '2'

    allow(scope).to receive(:count).and_return(2)
    allow(player_one).to receive(:update_player).and_raise(SocketError, 'network down')
    allow(player_two).to receive(:update_player)

    expect {
      task.invoke
    }.to output(/Network failures: 1.*Last id: 5/m).to_stdout

    expect(logger).to have_received(:warn).with('refetch_all: network error for Alpha (#4): network down')
    expect(player_two).to have_received(:update_player)
  end
end
