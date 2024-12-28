
## Purpose
Retrieve the TET coin balance for a given wallet address.

### Request Description
- **Method**: GET  
- **URL**: `/coins/balances`

### Request Parameters

| Parameter      | Required | Location | Data Type | Constraints   | Description                                      |
| -------------- | -------- | -------- | --------- | ------------- | ------------------------------------------------ |
| tet_address    | Yes      | Query    | String    | Valid address | The TET wallet address                           |

#### Example Request
GET /coins/balances?tet_address=0x535af33106dcdf40b68348fe227f7bee1347cae6

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter    | Required | Data Type | Constraints        | Description                |
| ------------ | -------- | --------- | ------------------ | -------------------------- |
| tet_balance  | Yes      | String    | Valid balance format| The balance of TET coins    |

#### Example Successful Response
```json
{
  "tet_balance": "3,9990498"
}
```

### Error Response
#### Common Error Response Structure

| Parameter | Required | Data Type | Description          |
| --------- | -------- | --------- | -------------------- |
| error     | Yes      | String    | Error code           |
| message   | Yes      | String    | Error description    |

### Error Codes

| Error Code              | HTTP Status Code  | Error Description                |
| ----------------------- | ----------------- | -------------------------------- |
| ADDRESS_NOT_EXISTS       | 400 Bad Request   | The address does not exist       |

#### Example Error Response
```json
{
  "error": "ADDRESS_NOT_EXISTS",
  "message": "the address does not exist"
}
```

### Workflow
1. The user sends a request with the TET wallet address.
2. The server returns the balance of the wallet.
3. If the address doesn't exist, the server returns an error.
