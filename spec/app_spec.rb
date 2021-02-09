require './spec/spec_helper.rb'
require 'functions_framework/testing'

describe  'OTP Functions' do 
  include FunctionsFramework::Testing

  describe 'Send OTP', redis: true do
    let(:phone_number) { "2347017927694" }
    let(:body) { { phone_number: phone_number }.to_json }
    let(:headers) { ["Content-Type: application/json"] }

    context 'when there is an active OTP' do
      before do
        redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new }
        Store.new(redis).set(phone_number, 1111)
      end

      it 'should return OTP previously sent' do
        load_temporary 'app.rb' do 
          request = make_post_request '/otp', body, headers

          response = call_http 'otp', request
          parsed_response = JSON.parse(response.body.join)
          expect(parsed_response['message']).to eq 'OTP previously sent'
        end
      end
    end

    it 'should send OTP successfully' do
      load_temporary "app.rb" do
        request = make_post_request "/otp", body, headers

        response = call_http "otp", request
        expect(response.status).to eq 200 
        expect(response.content_type).to eq("application/json")

        parsed_response = JSON.parse(response.body.join)
        expect(parsed_response['status']).to eq true
        expect(parsed_response['message']).to eq 'OTP sent successfully'

      end
    end
  end

  describe 'Verify OTP' do
    let(:phone_number) { "2347017927694" }
    let(:otp) { 1111 }
    let(:body) { { phone_number: phone_number, otp: otp }.to_json }
    let(:headers) { ["Content-Type: application/json"] }

    before do
      redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new }
      Store.new(redis).set(phone_number, otp)
    end

    it 'should verify OTP successfully' do
      load_temporary 'app.rb' do
        request = make_request '/otp/verify', method: ::Rack::PUT, 
          body: body, headers: headers
        response = call_http 'otp', request

        expect(response.status).to eq 200 
        expect(response.content_type).to eq("application/json")

        parsed_response = JSON.parse(response.body.join)
        expect(parsed_response['status']).to eq true
        expect(parsed_response['message']).to eq 'OTP verified'

      end
    end
  end
end
