
## Purpose
Authenticate an existing user with their login and password.

### Request Description
- **Method**: POST  
- **URL**: `/user/auth`

### Request Parameters

| Parameter    | Required | Location | Data Type | Constraints      | Description                     |
| ------------ | -------- | -------- | --------- | ---------------- | ------------------------------- |
| login        | Yes      | Body     | String    | Email format     | User login (email)              |
| password     | Yes      | Body     | String    | 8-64 characters  | User password                   |

#### Example Request in JSON Format
```json
{
  "login": "0x535af33106dcdf40b68348fe227f7bee1347cae6@softnote.com",
  "password": "624449863"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter    | Required | Data Type | Description                   |
| ------------ | -------- | --------- | ----------------------------- |
| session_key  | Yes      | String    | The session key for the user  |

#### Example Successful Response
```json
{
  "session_key": "iparHnFpVJvr3CnA1eigcE96UvBBT6Acr5"
}
```

### Error Response
#### Common Error Response Structure

| Parameter | Required | Data Type | Description          |
| --------- | -------- | --------- | -------------------- |
| error     | Yes      | String    | Error code           |
| message   | Yes      | String    | Error description    |

### Error Codes

| Error Code              | HTTP Status Code  | Error Description                  |
| ----------------------- | ----------------- | ---------------------------------- |
| AUTHORIZATION_FAILED    | 400 Bad Request   | Incorrect login or password        |

#### Example Error Response
```json
{
  "error": "AUTHORIZATION_FAILED",
  "message": "incorrect login or password"
}
```

### Workflow
1. The user sends a request with their login and password.
2. If the credentials are correct, the server returns a session key.
3. If the credentials are incorrect, the server returns an error.
