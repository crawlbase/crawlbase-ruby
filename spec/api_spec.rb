require 'spec_helper.rb'
require 'crawlbase'

describe Crawlbase::API do
  before(:each) do
    Crawlbase.instance_variable_set(:@pc_status_deprecation_warned, false)
  end

  it 'raises an error if token is missing' do
    expect { Crawlbase::API.new }.to raise_error(RuntimeError, 'Token is required')
  end

  it 'sets/reads token' do
    expect(Crawlbase::API.new(token: 'test').token).to eql('test')
  end

  it 'sets default timeout to 90 seconds' do
    expect(Crawlbase::API.new(token: 'test').timeout).to eql(90)
  end

  it 'sets a custom timeout' do
    expect(Crawlbase::API.new(token: 'test', timeout: 120).timeout).to eql(120)
  end

  describe '#get' do
    it 'sends an get request to Crawlbase API' do
      stub_request(:get, 'https://api.crawlbase.com/?token=test&url=http%3A%2F%2Fhttpbin.org%2Fanything%3Fparam1%3Dx%26params2%3Dy').
        to_return(
          body: 'body',
          status: 200,
          headers: { skip_normalize: true, 'original_status' => 200, 'pc_status' => 200, 'url' => 'http://httpbin.org/anything?param1=x&params2=y'})

      api = Crawlbase::API.new(token: 'test')

      response = api.get('http://httpbin.org/anything?param1=x&params2=y')

      expect(response.status_code).to eql(200)
      expect(response.original_status).to eql(200)
      expect(response.cb_status).to eql(200)
      expect(response.pc_status).to eql(200)
      expect(response.url).to eql('http://httpbin.org/anything?param1=x&params2=y')
      expect(response.body).to eql('body')
    end

    it 'resolves cb_status when only cb_status header is present' do
      stub_request(:get, 'https://api.crawlbase.com/?token=test&url=http%3A%2F%2Fexample.com').
        to_return(
          body: 'body',
          status: 200,
          headers: { skip_normalize: true, 'original_status' => 200, 'cb_status' => 201, 'url' => 'http://example.com'})

      response = Crawlbase::API.new(token: 'test').get('http://example.com')

      expect(response.cb_status).to eql(201)
      expect(response.pc_status).to eql(201)
    end

    it 'falls back to pc_status when cb_status header is absent' do
      stub_request(:get, 'https://api.crawlbase.com/?token=test&url=http%3A%2F%2Fexample.com').
        to_return(
          body: 'body',
          status: 200,
          headers: { skip_normalize: true, 'original_status' => 200, 'pc_status' => 202, 'url' => 'http://example.com'})

      response = Crawlbase::API.new(token: 'test').get('http://example.com')

      expect(response.cb_status).to eql(202)
      expect(response.pc_status).to eql(202)
    end

    it 'prefers cb_status when both cb_status and pc_status headers are present' do
      stub_request(:get, 'https://api.crawlbase.com/?token=test&url=http%3A%2F%2Fexample.com').
        to_return(
          body: 'body',
          status: 200,
          headers: {
            skip_normalize: true,
            'original_status' => 200,
            'cb_status' => 203,
            'pc_status' => 500,
            'url' => 'http://example.com'
          })

      response = Crawlbase::API.new(token: 'test').get('http://example.com')

      expect(response.cb_status).to eql(203)
      expect(response.pc_status).to eql(203)
    end

    it 'returns 0 when neither cb_status nor pc_status header is present' do
      stub_request(:get, 'https://api.crawlbase.com/?token=test&url=http%3A%2F%2Fexample.com').
        to_return(
          body: 'body',
          status: 200,
          headers: { skip_normalize: true, 'original_status' => 200, 'url' => 'http://example.com'})

      response = Crawlbase::API.new(token: 'test').get('http://example.com')

      expect(response.cb_status).to eql(0)
      expect(response.pc_status).to eql(0)
    end

    it 'resolves cb_status from JSON body keys' do
      stub_request(:get, 'https://api.crawlbase.com/?format=json&token=test&url=http%3A%2F%2Fexample.com').
        to_return(
          body: {
            'original_status' => 200,
            'cb_status' => 204,
            'pc_status' => 500,
            'url' => 'http://example.com'
          }.to_json,
          status: 200)

      response = Crawlbase::API.new(token: 'test').get('http://example.com', format: 'json')

      expect(response.cb_status).to eql(204)
      expect(response.pc_status).to eql(204)
    end

    it 'warns once when pc_status is accessed' do
      stub_request(:get, 'https://api.crawlbase.com/?token=test&url=http%3A%2F%2Fexample.com').
        to_return(
          body: 'body',
          status: 200,
          headers: { skip_normalize: true, 'pc_status' => 200, 'url' => 'http://example.com'})

      response = Crawlbase::API.new(token: 'test').get('http://example.com')

      expect { response.pc_status }.to output(/`pc_status` is deprecated/).to_stderr
      expect { response.pc_status }.not_to output(/`pc_status` is deprecated/).to_stderr
    end

    it 'raises a timeout error' do
      stub_request(:get, 'https://api.crawlbase.com/?token=test_with_timeout&url=http%3A%2F%2Fhttpbin.org%2Fdelay%2F3').to_timeout

      api = Crawlbase::API.new(token: 'test_with_timeout', timeout: 2)

      expect { api.get('http://httpbin.org/delay/3') }.to raise_error(Net::OpenTimeout)
    end
  end

  describe '#post' do
    it 'sends a post request to Crawlbase API with json data' do
      stub_request(:post, 'https://api.crawlbase.com/?post_content_type=json&token=test&url=http://httpbin.org/post').
        with(body: "{\"foo\":\"bar\"}").
        to_return(
          body: 'body',
          status: 200,
          headers: { skip_normalize: true, 'original_status' => 200, 'pc_status' => 200, 'url' => 'http://httpbin.org/anything?param1=x&params2=y'})

      api = Crawlbase::API.new(token: 'test')

      response = api.post("http://httpbin.org/post", { foo: 'bar' }, { post_content_type: 'json'} )

      expect(response.status_code).to eql(200)
      expect(response.original_status).to eql(200)
      expect(response.cb_status).to eql(200)
      expect(response.pc_status).to eql(200)
      expect(response.url).to eql('http://httpbin.org/anything?param1=x&params2=y')
      expect(response.body).to eql('body')
    end

    it 'sends a post request to Crawlbase API with form data' do
      stub_request(:post, 'https://api.crawlbase.com/?token=test&url=http://httpbin.org/post').
        with(body: { "foo" => "bar" }).
        to_return(
          body: 'body',
          status: 200,
          headers: { skip_normalize: true, 'original_status' => 200, 'pc_status' => 200, 'url' => 'http://httpbin.org/anything?param1=x&params2=y'})

      api = Crawlbase::API.new(token: 'test')

      response = api.post("http://httpbin.org/post", { foo: 'bar' } )

      expect(response.status_code).to eql(200)
      expect(response.original_status).to eql(200)
      expect(response.cb_status).to eql(200)
      expect(response.pc_status).to eql(200)
      expect(response.url).to eql('http://httpbin.org/anything?param1=x&params2=y')
      expect(response.body).to eql('body')
    end

    it 'raises a timeout error' do
      stub_request(:post, 'https://api.crawlbase.com/?token=test_with_timeout&url=http%3A%2F%2Fhttpbin.org%2Fdelay%2F3').to_timeout

      api = Crawlbase::API.new(token: 'test_with_timeout', timeout: 2)

      expect { api.post('http://httpbin.org/delay/3', {}) }.to raise_error(Net::OpenTimeout)
    end
  end
end
