require 'rails_helper'

RSpec.describe Clan, type: :model do
  describe '#authenticate_pass' do
    context 'with a bcrypt password' do
      let!(:clan) { Clan.create!(name: 'Test Clan', password: 'mypassword') }

      it 'authenticates the correct password' do
        expect(clan.authenticate_pass('mypassword')).to eq(clan)
      end

      it 'rejects a wrong password' do
        expect(clan.authenticate_pass('wrong')).to be(false)
      end

      it 'does not fall back to MD5 when a bcrypt digest exists' do
        clan.update!(pass: Digest::MD5.hexdigest('oldpassword'))

        expect(clan.authenticate_pass('oldpassword')).to be(false)
      end

      [nil, ''].each do |candidate|
        it "rejects #{candidate.inspect}" do
          expect(clan.authenticate_pass(candidate)).to be(false)
        end
      end
    end

    context 'with only a legacy MD5 password' do
      let!(:clan) { Clan.create!(name: 'Test Clan', pass: Digest::MD5.hexdigest('mypassword')) }

      it 'authenticates and persists a transparent bcrypt upgrade' do
        expect(clan.authenticate_pass('mypassword')).to eq(clan)
        expect(clan.reload.password_digest).to be_present
        expect(clan.authenticate('mypassword')).to eq(clan)
        expect(clan.authenticate_pass('mypassword')).to eq(clan)
      end

      it 'persists only the password digest, retaining the legacy hash' do
        original_attributes = clan.reload.attributes
        clan.description = 'Unsaved change'

        clan.authenticate_pass('mypassword')

        expect(clan.reload.attributes.except('password_digest')).to eq(original_attributes.except('password_digest'))
      end

      it 'rejects a wrong password without upgrading' do
        expect(clan.authenticate_pass('wrong')).to be(false)
        expect(clan.reload.password_digest).to be_nil
      end

      [nil, ''].each do |candidate|
        it "rejects #{candidate.inspect} without upgrading" do
          expect(clan.authenticate_pass(candidate)).to be(false)
          expect(clan.reload.password_digest).to be_nil
        end
      end
    end
  end

  describe '.find_clan' do
    let!(:clan) { Clan.create!(name: 'Test Clan') }

    it 'finds a clan by name case-insensitively' do
      expect(Clan.find_clan('tEsT cLaN')).to eq(clan)
    end

    ['Test_Clan', 'Test-Clan', "Test\u00a0Clan"].each do |name|
      it "normalizes #{name} for lookup" do
        expect(Clan.find_clan(name)).to eq(clan)
      end
    end

    it 'preserves the single-character wildcard for name separators' do
      clan.update!(name: 'TestXClan')

      expect(Clan.find_clan('Test Clan')).to eq(clan)
    end

    it 'does not match a substring of a longer clan name' do
      expect(Clan.find_clan('Test')).to be(false)
    end

    ["' OR '1'='1", "'); DROP TABLE clans; --"].each do |payload|
      it "rejects #{payload.inspect} without a SQL error or damaging the table" do
        expect { expect(Clan.find_clan(payload)).to be(false) }.not_to raise_error
        expect(Clan.count).to eq(1)
        expect(clan.reload.name).to eq('Test Clan')
      end
    end

    it 'binds the search term even if normalization allows SQL metacharacters' do
      payload = "' OR '1'='1"
      allow(Clan).to receive(:sanitize_name).with(payload).and_return(payload)

      expect { expect(Clan.find_clan(payload)).to be(false) }.not_to raise_error
      expect(clan.reload.name).to eq('Test Clan')
    end

    it 'falls back to looking up a numeric ID' do
      expect(Clan.find_clan(clan.id.to_s)).to eq(clan)
    end

    it 'returns false for a missing numeric ID' do
      expect(Clan.find_clan((Clan.maximum(:id) + 1).to_s)).to be(false)
    end
  end

  describe '#remove_player' do
    it 'removes only links for the specified clan and player' do
      clan = Clan.create!(name: 'Test Clan')
      other_clan = Clan.create!(name: 'Other Clan')
      player = Player.create!(player_name: 'Test Player', player_acc_type: 'Reg')
      other_player = Player.create!(player_name: 'Other Player', player_acc_type: 'Reg')
      removed_link = clan.add_player(player)
      retained_links = [clan.add_player(other_player), other_clan.add_player(player)]

      clan.remove_player(player)

      expect(PlayerClanLink.exists?(removed_link.id)).to be(false)
      expect(PlayerClanLink.where(id: retained_links.map(&:id)).count).to eq(2)
    end
  end
end
