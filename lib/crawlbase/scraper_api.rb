# frozen_string_literal: true

module Crawlbase
  class ScraperAPI < Crawlbase::API
    attr_reader :remaining_requests

    def post
      raise 'Only GET is allowed for the ScraperAPI'
    end

    private

    def prepare_response(response, format)
      super(response, format)
      json_body = JSON.parse(response.body)
      @remaining_requests = json_body['remaining_requests'].to_i
    end

    def base_url
      'https://api.crawlbase.com/scraper'
    end
  end
end
