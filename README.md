# otp-cloud-function
Google Cloud Function to Send, Verify &amp; Resend OTP with Ruby.

# APIs
- `POST /otp`: Sends OTP to the phone number.
```
# Request
{
	"phone_number": "07015971724",
}

# Response
{
	"status": true,
	"message": "OTP Sent successfully",
	"data": {
		"phone_number": "07015971724"
	}
}

```


