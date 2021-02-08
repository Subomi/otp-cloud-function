require 'active_support/concern'
require 'active_support/core_ext/numeric/time'

Record = Struct.new(:phone_number, :otp, :expires_at) do 
  def serialize
    to_h.to_json
  end

  def deserialize(data)
    JSON.parse(data)
  end

  def expired?
    Time.now > Time.at(expires_at)
  end

end


class Store
  def initialize(connection_pool)
    @connection_pool = connection_pool
  end

  def set(phone_number, otp)
    expires_at = (Time.now + 9.minutes).to_i
    record = Record.new(phone_number, otp, expires_at)
    @connection_pool.with do |conn|
      conn.set(phone_number, record.serialize)
    end

    record
  end

  def get(phone_number)
    data = @connection_pool.with do |conn|
      conn.get(phone_number)
    end

    return nil if data.nil?
    record = Record.new
    data = record.deserialize(data) 

    record['phone_number'] = data['phone_number']
    record['otp'] = data['otp']
    record['expires_at'] = data['expires_at']

    record
  end

  def del(phone_number)
    @connection_pool.with do |conn|
      conn.del(phone_number)
    end
  end
end
