## Purpose
Сreate a new crypto wallet based on a key pair and seed phrase.

### Request Description
- **Method**: GET 
- **URL**: `/keys/new`

### Request Parameters
No parameters are required for this request.

#### Example Request in JSON Format
```
GET /keys/new
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter        | Required | Data Type | Description                                      |
| ---------------- | -------- | --------- | ------------------------------------------------ |
| seed_phrase      | Yes      | String    | Seed phrase to restore access to crypto address  |
| private_key      | Yes      | String    | Private key of the new crypto address            |
| public_key       | Yes      | String    | Public key of the new crypto address             |
| address          | Yes      | String    | New user crypto address                          |

#### Example Successful Response
```json
{
  "seed_phrase":"test test test test test test test test test test test test",
  "private_key":"1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d",
  "public_key":"0p0p0p0p0p0p0p0p0p0p0p0p00p0p0p0p0p0p00p0p0p0p0p0p0p0p00p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0",
  "address":"0xp0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0"
}
```

### Workflow
1. The user sends a request to generate a new crypto wallet.
2. The server returns data from his new crypto wallet to him.
