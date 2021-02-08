# Cloud Functions Entrypoint

require 'functions_framework'
require 'connection_pool'
require 'active_model_serializers'
require './lib/store'
require './lib/send_sms_notification'
require './lib/response'
require './lib/serializers/models/base_model'
require './lib/serializers/models/otp_response'
require './lib/serializers/application_serializer'
require './lib/serializers/base_model_serializer'
require './lib/serializers/otp_response_serializer'


FunctionsFramework.on_startup do |function|
  # Setup Shared Redis Client
  require 'redis'
  set_global :redis_client, ConnectionPool.new(size: 5, timeout: 5) { Redis.new }
end

FunctionsFramework.http "otp" do |request|

  store = Store.new(global(:redis_client))
  data = JSON.parse(request.body.read)

  if  request.post? && request.path == '/otp'
    phone_number = data['phone_number']
    record = store.get(phone_number)
    data = Models::OtpResponse.new(phone_number: phone_number,
                                   otp: record['otp'],
                                   expires_at: record['expires_at'])
    json = Response.generate_json(status: true, 
                         message: 'OTP previously sent',
                         data: data)

    return json unless record.nil? || record.expired?

    otp = rand(1111..9999)
    record = store.set(phone_number, otp)
    SendSmsNotification.new(phone_number, otp)

    data = Models::OtpResponse.new(phone_number: phone_number,
                                   otp: record['otp'],
                                   expires_at: record['expires_at'])

    json = Response.generate_json(status: true, 
                         message: 'OTP sent successfully',
                         data: data)
  elsif request.put? && request.path == '/otp/verify'
    phone_number = data['phone_number']
    record = store.get(phone_number)
    
    if record.nil?
      return Response.generate_json(status: false, message: "OTP not sent to number")
    elsif record.expired?
      return Response.generate_json(status: false,  message: 'OTP code expired')
    end

    is_verified = data['otp'] == record['otp']

    if is_verified
      return Response.generate_json(status: true, message: 'OTP verified')
    else
      return Response.generate_json(status: false, message: 'OTP does not match')
    end

  elsif request.put? && request.path == '/otp/resend'
    phone_number = data['phone_number']
    store.del(phone_number)

    otp = rand(1111..9999)
    record = store.set(phone_number, otp)
    SendSmsNotification.new(phone_number, otp)

    data = Models::OtpResponse.new(phone_number: phone_number,
                                   otp: record['otp'],
                                   expires_at: record['expires_at'])

    json = Response.generate_json(status: true, 
                         message: 'OTP sent successfully',
                         data: data)
  else
    "Error: Request method and path didn't match"
  end
end
