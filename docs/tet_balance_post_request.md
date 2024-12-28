
## Purpose
Retrieve the TET coin balance for a given wallet address.

### Request Description
- **Method**: POST  
- **URL**: `/coins/balances`

### Request Parameters

| Parameter    | Required | Location | Data Type | Constraints      | Description                     |
| ------------ | -------- | -------- | --------- | ---------------- | ------------------------------- |
| tet_address  | Yes      | Body     | String    | Valid address    | The TET wallet address          |

#### Example Request in JSON Format
```json
{
  "tet_address": "0x7954a8ccf2f65e888d4a5f7bbc6c81a01cad8e6c"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter    | Required | Data Type | Constraints          | Description                |
| ------------ | -------- | --------- | -------------------- | -------------------------- |
| tet_balance  | Yes      | String    | Valid balance format  | The balance of TET coins    |

#### Example Successful Response
```json
{
  "tet_balance": "1,506"
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
| ADDRESS_NOT_EXISTS       | 400 Bad Request   | The address does not exist         |

#### Example Error Response
```json
{
  "error": "ADDRESS_NOT_EXISTS",
  "message": "the address does not exists"
}
```

### Workflow
1. The user sends a request with the TET wallet address.
2. The server returns the balance of the wallet.
3. If the address doesn't exist, the server returns an error.
