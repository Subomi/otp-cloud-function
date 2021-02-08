# Cloud Functions Entrypoint

require 'functions_framework'
require 'connection_pool'
require './lib/store'
require './lib/send_sms_notification'

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
    return record.serialize unless record.nil? || record.expired?

    otp = rand(1111..9999)
    record = store.set(phone_number, otp)
    SendSmsNotification.new(phone_number, otp)

    record.serialize
  elsif request.put? && request.path == '/otp/verify'
    phone_number = data['phone_number']
    record = store.get(phone_number)
    
    if record.nil?
      return { status: false, message: "OTP not sent to number" }
    elsif record.expired?
      return { status: false,  message: 'OTP code expired' }
    end

    is_verified = data['otp'] == record['otp']

    if is_verified
      return { status: true, message: 'OTP verified' }
    else
      return { status: false, message: 'OTP does not match' }
    end

  elsif request.put? && request.path == '/otp/resend'
    phone_number = data['phone_number']
    store.del(phone_number)

    otp = rand(1111..9999)
    record = store.set(phone_number, otp)
    SendSmsNotification.new(phone_number, otp)

    record.serialize
  else
    "Error: Request method and path didn't match"
  end
end
