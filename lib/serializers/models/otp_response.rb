module Models
  class OtpResponse < ActiveModelSerializers::Model
    attributes :phone_number, :otp, :expires_at
  end
end
