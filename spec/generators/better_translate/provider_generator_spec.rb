# frozen_string_literal: true

require 'spec_helper'
require 'generators/better_translate/provider_generator'

RSpec.describe BetterTranslate::Generators::ProviderGenerator, type: :generator do
  destination File.expand_path('../../tmp', __dir__)

  before do
    prepare_destination
    # Mock Rails.root for testing
    allow_any_instance_of(BetterTranslate::Generators::ProviderGenerator).to receive(:destination_root).and_return(destination_root)
  end

  after do
    # Clean up generated files
    FileUtils.rm_rf(destination_root)
  end

  context 'when generating a custom provider' do
    it 'creates the provider file with the correct content' do
      run_generator ['DeepL']
      
      # Check that the provider file was created
      assert_file 'app/providers/deep_l_provider.rb' do |content|
        # Check that the file contains the expected content
        expect(content).to include('class DeepLProvider < BetterTranslate::Providers::BaseProvider')
        expect(content).to include('def translate_text(text, target_lang_code, target_lang_name)')
        expect(content).to include('module Providers')
      end
      
      # Check that the providers directory was created
      assert_directory 'app/providers'
    end
  end
end
