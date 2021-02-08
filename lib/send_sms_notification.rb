class SendSmsNotification
  def initialize(phone_number, otp)
    @phone_number = phone_number
    @otp = otp
  end

  def call
    body = "Your OTP is #{@otp}"
    account_sid = ENV['TWILIO_ACCOUNT_SID']
    auth_token = ENV['TWILIO_AUTH_TOKEN']
    from = ENV['TWILIO_PHONE_NUMBER']

    client = Twilio::REST::Client.new account_sid, auth_token
    client.messages.create(
      from: from,
      to: @phone_number,
      body: body
    )
  end
end
