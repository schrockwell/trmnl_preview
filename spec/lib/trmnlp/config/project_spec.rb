# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe TRMNLP::Config::Project do
  subject(:project) { described_class.new(paths) }

  let(:root_dir) { File.join(__dir__, '../../../fixtures') }
  let(:paths) { TRMNLP::Paths.new(root_dir) }

  describe '#custom_fields' do
    it 'transforms scalar values to strings' do
      expect(project.custom_fields).to include('character_name' => 'Bluey', 'character_age' => '7')
    end

    it 'preserves arrays as arrays (multi-select fields, issue #80)' do
      expect(project.custom_fields).to include('favorite_episodes' => %w[Sleepytime Camping])
    end

    it 'stringifies elements within arrays for parity with the hosted service' do
      expect(project.custom_fields).to include('rolls' => %w[1 2])
    end

    it 'recursively stringifies nested array and hash values' do
      config = {
        'custom_fields' => {
          'nested' => {
            'items' => [1, { 'value' => 2 }, [3, 4]],
            'enabled' => true
          }
        }
      }
      project.instance_variable_set(:@config, config)

      expect(project.custom_fields).to include(
        'nested' => {
          'items' => ['1', { 'value' => '2' }, %w[3 4]],
          'enabled' => 'true'
        }
      )
    end

    context 'when there is no .trmnlp yaml file in the path' do
      let(:root_dir) { 'not-a-valid-path' }

      it 'returns an empty hash' do
        expect(project.custom_fields).to eq({})
      end
    end
  end

  describe '#with_custom_fields' do
    before { project.instance_variable_set(:@config, { 'custom_fields' => { 'city' => 'Perth' } }) }

    it 'renders custom field values' do
      expect(project.with_custom_fields('in {{ city }}')).to eq('in Perth')
    end

    it 'merges extra variables into the render context' do
      rendered = project.with_custom_fields('Bearer {{ oauth_access_token }}',
                                            extra_variables: { 'oauth_access_token' => 'AT' })
      expect(rendered).to eq('Bearer AT')
    end
  end

  describe '#serverless_daemon_api_key' do
    let(:root_dir) { 'not-a-valid-path' }

    it 'reads from $TRMNL_SERVERLESS_DAEMON_API_KEY when set' do
      stub_const('ENV', ENV.to_h.merge('TRMNL_SERVERLESS_DAEMON_API_KEY' => 'from-env'))
      expect(project.serverless_daemon_api_key).to eq('from-env')
    end

    it 'returns nil when neither env nor config provides one' do
      stub_const('ENV', ENV.to_h.except('TRMNL_SERVERLESS_DAEMON_API_KEY'))
      expect(project.serverless_daemon_api_key).to be_nil
    end
  end

  describe '#transform_runtime' do
    it 'defaults to enabled when .trmnlp.yml does not configure it' do
      expect(project.transform_runtime).to eq('enabled')
    end

    context 'when .trmnlp.yml opts out' do
      before { project.instance_variable_set(:@config, { 'transform_runtime' => 'disabled' }) }

      it 'returns the configured value' do
        expect(project.transform_runtime).to eq('disabled')
      end
    end
  end

  describe '#reload!' do
    it 'raises a readable InvalidConfig when .trmnlp.yml is not valid YAML' do
      Dir.mktmpdir('trmnlp-project-') do |dir|
        File.write(File.join(dir, '.trmnlp.yml'), 'watch: [unclosed')

        expect { described_class.new(TRMNLP::Paths.new(dir)) }
          .to raise_error(TRMNLP::InvalidConfig, /\.trmnlp\.yml is not valid YAML/)
      end
    end
  end
end
