require 'spec_helper'

RSpec.describe RubyBranch::API::Resources::Link do
  let(:analytics_sample) do
    {
      feature: :partner,
      tags: %i[greeting asd]
    }
  end
  let(:data_sample) do
    {
      feature: :join_to_story,
      '$og_description' => "Join Jonh's story!",
      story_id: 1
    }
  end
  let(:long_data_sample) do
    data = data_sample.dup
    data.tap do |d|
      d[:description] = 'Lorem Ipsum' * (RubyBranch::API::Resources::Link::LINK_LENGTH_LIMIT + 1)
    end
  end
  let(:api_key) { 'APIKEY' }
  let(:branch_domain) { 'mydomain.app.link' }

  before do
    RubyBranch.configure do |config|
      config.api_key = api_key
      config.branch_domain = branch_domain
      config.link_to_homepage = 'https://mydomain.com'
    end
  end

  subject(:link) { described_class.new }

  describe '#create_safely' do
    it 'works' do
      expect(link).to receive(:build)
      link.create_safely(analytics: analytics_sample, data: data_sample)
    end

    it 'fallbacks to create link with api if build link fails with length exceed error' do
      expect(link).to receive(:create)
      link.create_safely(analytics: analytics_sample, data: long_data_sample)
    end
  end

  describe '#update_safely' do
    let(:branch_url) { 'http://mydomain.app.link/cedk/welkrje' }

    it 'works' do
      expect(link).to receive(:build)
      link.update_safely(url: branch_url, analytics: analytics_sample, data: data_sample)
    end
  end

  describe '#build' do
    it 'constructs branch link' do
      resulted_link = link.build(analytics: analytics_sample, data: data_sample)
      expect_link_includes_domain_and_path(resulted_link)
      expect_link_includes_query_params(resulted_link, params: { story_id: 1 })
    end

    context 'link length exceed limit' do
      it 'raises an error' do
        expect do
          link.build(analytics: analytics_sample, data: long_data_sample)
        end.to raise_error(RubyBranch::Errors::LinkLengthExceedError)
      end
    end

    it 'with empty params' do
      resulted_link = link.build
      expect_link_includes_domain_and_path(resulted_link)
    end
  end

  describe '#create' do
    it 'returns link' do
      branch_url = 'http://mydomain.app.link/cedk/welkrje'
      stub_create_request_to_branch_to_return_url(branch_url)
      resulted_link = link.create(analytics: analytics_sample, data: data_sample)
      expect(resulted_link).to eq(branch_url)
    end

    context 'branch is down' do
      before do
        stub_create_request_to_branch_to_return_502_error
      end

      it 'returns root url' do
        resulted_link = link.create
        expect(resulted_link).to eq RubyBranch.config.link_to_homepage
      end
    end
  end

  describe '#update' do
    let(:branch_url) { 'http://mydomain.app.link/cedk/welkrje' }

    it 'returns true' do
      stub_update_request_to_branch_to_return_url(branch_url)
      data_sample['$og_description'] = "Join Sam's story"
      result = link.update(url: branch_url, analytics: analytics_sample, data: data_sample)
      expect(result).to eq(true)
    end

    context 'branch is down' do
      before do
        stub_update_request_to_branch_to_return_502_error
      end

      it 'returns false' do
        result = link.update(url: branch_url)
        expect(result).to eq false
      end
    end
  end

  def expect_link_includes_domain_and_path(link)
    parse_link(link)
    expect(@parsed_link.scheme).to eq 'https'
    expect(@parsed_link.host).to eq(branch_domain)
    expect(@parsed_link.path).to eq("/a/#{api_key}")
  end

  def expect_link_includes_query_params(link, params:)
    parse_link(link)
    query_params = parse_query(@parsed_link.query)
    params.each do |param_name, param_value|
      param_value = if param_value.is_a?(Array)
                      param_value.map(&:to_s)
                    else
                      param_value.to_s
                    end
      expect(query_params[param_name.to_s]).to eq(param_value)
    end
  end

  def parse_query(qs, d = '&;')
    params = {}

    (qs || '').split(/[#{d}] */n).each do |p|
      k, v = URI.unescape(p).split('=', 2)
      params[k] = v
    end

    params
  end

  def parse_link(link)
    @parsed_link ||= URI.parse(link)
  end

  def stub_create_request_to_branch_to_return_url(url)
    stub_request(:post, %r{#{RubyBranch::BRANCH_API_ENDPOINT}\/*})
      .to_return(status: [200], body: "{\"url\":\"#{url}\"}")
  end

  def stub_update_request_to_branch_to_return_url(url)
    stub_request(:put, %r{#{RubyBranch::BRANCH_API_ENDPOINT}\/*})
      .to_return(status: [200], body: "{\"url\":\"#{url}\"}")
  end

  def stub_create_request_to_branch_to_return_502_error
    stub_request(:post, %r{#{RubyBranch::BRANCH_API_ENDPOINT}\/*})
      .to_return(status: [502, 'Bad Gateway'])
  end

  def stub_update_request_to_branch_to_return_502_error
    stub_request(:put, %r{#{RubyBranch::BRANCH_API_ENDPOINT}\/*})
      .to_return(status: [502, 'Bad Gateway'])
  end
end
