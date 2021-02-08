module Response
  class SerializationError < StandardError
  end

  def self.generate_json(status: true, message: 'success', data: {})
    data = Models::BaseModel.new(status: status, message: message, data: data)
    ActiveModelSerializers::SerializableResource.new(data).as_json
  rescue StandardError => e
    raise SerializationError, "response could not be serialized: #{e.message}"
  end
end
