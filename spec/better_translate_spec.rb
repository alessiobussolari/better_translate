# frozen_string_literal: true

RSpec.describe BetterTranslate do
  it "has a version number" do
    expect(BetterTranslate::VERSION).not_to be nil
  end

  describe '.configure' do
    it 'allows configuration of provider and API keys' do
      BetterTranslate.configure do |config|
        config.provider = :chatgpt
        config.openai_key = 'test_key'
      end

      expect(BetterTranslate.configuration.provider).to eq(:chatgpt)
      expect(BetterTranslate.configuration.openai_key).to eq('test_key')
    end
  end
end
