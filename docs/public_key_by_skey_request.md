
## Purpose
Retrieve the public key associated with a session key.

### Request Description
- **Method**: GET  
- **URL**: `/keys/public/byskey`

### Request Parameters

| Parameter     | Required | Location | Data Type | Constraints      | Description                           |
| ------------- | -------- | -------- | --------- | ---------------- | ------------------------------------- |
| session_key   | Yes      | Query    | String    | Valid session key | The user's session key                |

#### Example Request
```
GET /keys/public/byskey?session_key=ipaTWBRJRPNDDcDNL7hoRam7FSTY0jrYbX
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter    | Required | Data Type | Constraints            | Description                       |
| ------------ | -------- | --------- | ---------------------- | --------------------------------- |
| public_key   | Yes      | String    | Valid public key format| The user's public key             |

#### Example Successful Response
```json
{
  "public_key": "047b9c81b035193baea18625e5c5e0baf7bd5786b10435464bc895c459f4aeab059b72d58f535234feb8943128f38197a7d346702991d712f2850173f2328643ae"
}
```

### Error Response
#### Common Error Response Structure

| Parameter | Required | Data Type | Description          |
| --------- | -------- | --------- | -------------------- |
| error     | Yes      | String    | Error code           |
| message   | Yes      | String    | Error description    |

### Error Codes

| Error Code                  | HTTP Status Code  | Error Description                  |
| --------------------------- | ----------------- | ---------------------------------- |
| VALIDATION_FAILED            | 400 Bad Request   | The session key is incorrect       |

#### Example Error Response
```json
{
  "error": "VALIDATION_FAILED",
  "message": "incorrect session key"
}
```

### Workflow
1. The user sends a request with a valid session key.
2. The server returns the public key associated with the session key.
3. If the session key is invalid, the server returns an error.
