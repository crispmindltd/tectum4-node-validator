
## Purpose
Retrieve the smart contract address by its token ticker.

### Request Description
- **Method**: GET  
- **URL**: `/tokens/address/byticker`

### Request Parameters

| Parameter   | Required | Location | Data Type | Constraints      | Description                           |
| ----------- | -------- | -------- | --------- | ---------------- | ------------------------------------- |
| ticker      | Yes      | Query    | String    | None             | Token ticker symbol                   |

#### Example Request
```
GET /tokens/address/byticker?ticker=kar
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter      | Required | Data Type | Constraints         | Description                       |
| -------------- | -------- | --------- | ------------------- | --------------------------------- |
| smart_address  | Yes      | String    | Valid address format| The smart contract's address      |

#### Example Successful Response
```json
{
  "smart_address": "0x4752cbb6b5f0d60b816188163f35d4128da9fa75"
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
| SMARTCONTRACT_NOT_EXISTS     | 400 Bad Request   | The smart contract does not exist  |

#### Example Error Response
```json
{
  "error": "SMARTCONTRACT_NOT_EXISTS",
  "message": "smart contract does not exists"
}
```

### Workflow
1. The user sends a request with the token ticker.
2. The server returns the smart contract address if the ticker is valid.
3. If the ticker is invalid or doesn't exist, the server returns an error with details.
