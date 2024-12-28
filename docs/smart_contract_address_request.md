
## Purpose
Retrieve the smart contract address by its ID.

### Request Description
- **Method**: GET  
- **URL**: `/tokens/address/byid`

### Request Parameters

| Parameter   | Required | Location | Data Type | Constraints      | Description                           |
| ----------- | -------- | -------- | --------- | ---------------- | ------------------------------------- |
| smart_id    | Yes      | Query    | Integer   | Positive value   | The unique ID of the smart contract   |

#### Example Request
```
GET /tokens/address/byid?smart_id=24
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
  "smart_address": "0x211865ed10ce8b42ed3ddf63302c7b3d4b7d68d2"
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
| VALIDATION_FAILED       | 400 Bad Request   | Invalid smart contract ID          |

#### Example Error Response
```json
{
  "error": "VALIDATION_FAILED",
  "message": "invalid smart ID"
}
```

### Workflow
1. The user sends a request with the smart contract ID.
2. The server returns the smart contract address if the ID is valid.
3. If the ID is invalid, the server returns an error with details.
