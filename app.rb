# Cloud Functions Entrypoint

require 'functions_framework'

FunctionsFramework.on_startup do |function|
  # Setup Shared Redis Client
end

FunctionsFramework.http "otp" do |request|
  # Return the response body.
  "Hello, world!\n"
end
