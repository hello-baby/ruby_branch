require 'spec_helper'

RSpec.describe RubyBranch do
  it 'has a version number' do
    expect(RubyBranch::VERSION).not_to be nil
  end

  describe '#configure' do
    before :each do
      RubyBranch.configure do |config|
        config.api_key = 'api_key'
        config.branch_domain = 'branch_domain'
        config.link_to_homepage = 'https://mydomain.com'
      end
    end

    it 'returns configuration options' do
      expect(RubyBranch.config.api_key).to eq('api_key')
      expect(RubyBranch.config.branch_domain).to eq('branch_domain')
      expect(RubyBranch.config.link_to_homepage).to eq('https://mydomain.com')
    end

    after :each do
      RubyBranch.reset
    end
  end
end
