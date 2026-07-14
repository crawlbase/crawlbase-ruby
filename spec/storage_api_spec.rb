require 'spec_helper'
require 'crawlbase'

describe Crawlbase::StorageAPI do
  before(:each) do
    Crawlbase.instance_variable_set(:@pc_status_deprecation_warned, false)
  end

  it 'raises an error if token is missing' do
    expect { Crawlbase::StorageAPI.new }.to raise_error(RuntimeError, 'Token is required')
  end

  context '#get' do
    before(:each) do
      stub_request(:get, 'https://api.crawlbase.com/storage?format=html&rid=1&token=test')
        .to_return(
          status: 200,
          body: {
            stored_at: '2021-03-01T14:22:58+02:00',
            original_status: 200,
            pc_status: 200,
            rid: '1',
            url: 'https://www.apple.com',
            body: '<html><head><title>Apple</title></head><body>Apple</body></html>'
          }.to_json
        )
    end

    subject { Crawlbase::StorageAPI.new(token: 'test') }

    it 'raises an error if parameter is missing' do
      expect { subject.get(nil) }.to raise_error(RuntimeError, 'Either URL or RID is required')
    end

    it 'returns storage info' do
      subject.get('1')
      expect(subject.body).to eq(
        {
          stored_at: '2021-03-01T14:22:58+02:00',
          original_status: 200,
          pc_status: 200,
          rid: '1',
          url: 'https://www.apple.com',
          body: '<html><head><title>Apple</title></head><body>Apple</body></html>'
        }.to_json
      )
    end

    it 'resolves cb_status from JSON body with only cb_status' do
      stub_request(:get, 'https://api.crawlbase.com/storage?format=json&rid=1&token=test')
        .to_return(
          status: 200,
          body: {
            'stored_at' => '2021-03-01T14:22:58+02:00',
            'original_status' => 200,
            'cb_status' => 201,
            'rid' => '1',
            'url' => 'https://www.apple.com'
          }.to_json
        )

      subject.get('1', 'json')
      expect(subject.cb_status).to eq(201)
      expect(subject.pc_status).to eq(201)
    end

    it 'falls back to pc_status from JSON body when cb_status is absent' do
      stub_request(:get, 'https://api.crawlbase.com/storage?format=json&rid=1&token=test')
        .to_return(
          status: 200,
          body: {
            'stored_at' => '2021-03-01T14:22:58+02:00',
            'original_status' => 200,
            'pc_status' => 202,
            'rid' => '1',
            'url' => 'https://www.apple.com'
          }.to_json
        )

      subject.get('1', 'json')
      expect(subject.cb_status).to eq(202)
      expect(subject.pc_status).to eq(202)
    end

    it 'prefers cb_status when both keys are present in JSON body' do
      stub_request(:get, 'https://api.crawlbase.com/storage?format=json&rid=1&token=test')
        .to_return(
          status: 200,
          body: {
            'stored_at' => '2021-03-01T14:22:58+02:00',
            'original_status' => 200,
            'cb_status' => 203,
            'pc_status' => 500,
            'rid' => '1',
            'url' => 'https://www.apple.com'
          }.to_json
        )

      subject.get('1', 'json')
      expect(subject.cb_status).to eq(203)
      expect(subject.pc_status).to eq(203)
    end

    it 'returns 0 when neither cb_status nor pc_status is present' do
      stub_request(:get, 'https://api.crawlbase.com/storage?format=json&rid=1&token=test')
        .to_return(
          status: 200,
          body: {
            'stored_at' => '2021-03-01T14:22:58+02:00',
            'original_status' => 200,
            'rid' => '1',
            'url' => 'https://www.apple.com'
          }.to_json
        )

      subject.get('1', 'json')
      expect(subject.cb_status).to eq(0)
      expect(subject.pc_status).to eq(0)
    end
  end

  context '#delete' do
    subject { Crawlbase::StorageAPI.new(token: 'test') }

    it 'raises an error if parameter is missing' do
      expect { subject.delete(nil) }.to raise_error(RuntimeError, 'RID is required')
    end
  end

  context '#bulk' do
    before(:each) do
      stub_request(:post, 'http://api.crawlbase.com/storage/bulk?token=test')
        .with(
          body: { rids: %w[1 2 3] }.to_json
        )
        .to_return(
          status: 200,
          body: [
            {
              stored_at: '2021-03-01T14:22:58+02:00',
              original_status: 200,
              pc_status: 200,
              rid: '1',
              url: 'https://www.apple.com',
              body: '<html><head><title>Apple</title></head><body>Apple</body></html>'
            },
            {
              stored_at: '2021-03-02T14:22:58+02:00',
              original_status: 200,
              pc_status: 200,
              rid: '2',
              url: 'https://www.google.com',
              body: '<html><head><title>Google</title></head><body>Google</body></html>'
            },
            {
              stored_at: '2021-03-03T14:22:58+02:00',
              original_status: 200,
              pc_status: 200,
              rid: '3',
              url: 'https://www.espn.com',
              body: '<html><head><title>ESPN</title></head><body>ESPN</body></html>'
            }
          ].to_json
        )
    end

    subject { Crawlbase::StorageAPI.new(token: 'test') }

    it 'raises an error if parameter is missing' do
      expect { subject.bulk([]) }.to raise_error(RuntimeError, 'One or more RIDs are required')
    end

    it 'returns an an array of storage info' do
      subject.bulk(%w[1 2 3])
      expect(subject.body).to eq(
        [
          { 
            'body' => '<html><head><title>Apple</title></head><body>Apple</body></html>',
            'original_status' => 200,
            'pc_status' => 200,
            'rid' => '1',
            'stored_at' => '2021-03-01T14:22:58+02:00',
            'url' => 'https://www.apple.com' 
          },
          {
            'body' => '<html><head><title>Google</title></head><body>Google</body></html>',
            'original_status' => 200,
            'pc_status' => 200,
            'rid' => '2',
            'stored_at' => '2021-03-02T14:22:58+02:00',
            'url' => 'https://www.google.com' 
          },
          {
            'body' => '<html><head><title>ESPN</title></head><body>ESPN</body></html>',
            'original_status' => 200,
            'pc_status' => 200,
            'rid' => '3',
            'stored_at' => '2021-03-03T14:22:58+02:00',
            'url' => 'https://www.espn.com' 
          }
        ]
      )
      expect(subject.rid).to eq(%w[1 2 3])
      expect(subject.stored_at).to eq(
        [
          '2021-03-01T14:22:58+02:00',
          '2021-03-02T14:22:58+02:00',
          '2021-03-03T14:22:58+02:00'
        ]
      )
      expect(subject.url).to eq(
        [
          'https://www.apple.com',
          'https://www.google.com',
          'https://www.espn.com'
        ]
      )
      expect(subject.cb_status).to eq([200, 200, 200])
      expect(subject.pc_status).to eq([200, 200, 200])
    end

    it 'resolves per-item cb_status with preference over pc_status' do
      stub_request(:post, 'http://api.crawlbase.com/storage/bulk?token=test')
        .with(body: { rids: %w[1 2 3] }.to_json)
        .to_return(
          status: 200,
          body: [
            {
              'stored_at' => '2021-03-01T14:22:58+02:00',
              'original_status' => 200,
              'cb_status' => 201,
              'rid' => '1',
              'url' => 'https://www.apple.com'
            },
            {
              'stored_at' => '2021-03-02T14:22:58+02:00',
              'original_status' => 200,
              'pc_status' => 202,
              'rid' => '2',
              'url' => 'https://www.google.com'
            },
            {
              'stored_at' => '2021-03-03T14:22:58+02:00',
              'original_status' => 200,
              'cb_status' => 203,
              'pc_status' => 500,
              'rid' => '3',
              'url' => 'https://www.espn.com'
            }
          ].to_json
        )

      subject.bulk(%w[1 2 3])
      expect(subject.cb_status).to eq([201, 202, 203])
      expect(subject.pc_status).to eq([201, 202, 203])
    end
  end

  context '#rids' do
    before(:each) do
      stub_request(:get, 'https://api.crawlbase.com/storage/rids?token=test')
        .to_return(
          body: %w[1 2 3].to_json,
          status: 200,
          headers: { skip_normalize: true }
        )
    end

    subject { Crawlbase::StorageAPI.new(token: 'test') }

    it 'returns an array of rids' do
      expect(subject.rids).to eq(%w[1 2 3])
      expect(subject.body).to eq(%w[1 2 3])
      expect(subject.rid).to eq(%w[1 2 3])
    end
  end

  context '#total_count' do
    before(:each) do
      stub_request(:get, 'https://api.crawlbase.com/storage/total_count?token=test')
        .to_return(
          body: '{"totalCount": 123}',
          status: 200,
          headers: { skip_normalize: true }
        )
    end

    subject { Crawlbase::StorageAPI.new(token: 'test') }

    it 'returns the total count' do
      expect(subject.total_count).to eq(123)
    end
  end
end
