require 'rails_helper'

RSpec.describe PlayersHelper, type: :helper do
  describe '#display_rank' do
    it 'converts -1 to 0' do
      expect(helper.display_rank(-1)).to eq(0)
    end

    it 'converts "-1" string to 0' do
      expect(helper.display_rank("-1")).to eq(0)
    end

    it 'returns positive ranks unchanged' do
      expect(helper.display_rank(1)).to eq(1)
      expect(helper.display_rank(100)).to eq(100)
      expect(helper.display_rank(999999)).to eq(999999)
    end

    it 'returns 0 rank unchanged' do
      expect(helper.display_rank(0)).to eq(0)
    end

    it 'handles nil by converting to 0' do
      expect(helper.display_rank(nil)).to eq(0)
    end

    it 'handles string ranks' do
      expect(helper.display_rank("42")).to eq(42)
      expect(helper.display_rank("1000")).to eq(1000)
    end
  end
end
