
## Purpose
Transfer TET coins from one wallet to another.

### Request Description
- **Method**: POST  
- **URL**: `/coins/transfer`

### Request Parameters

| Parameter     | Required | Location | Data Type | Constraints       | Description                      |
| ------------- | -------- | -------- | --------- | ----------------- | -------------------------------- |
| session_key   | Yes      | Body     | String    | Valid session key | The session key of the user      |
| to            | Yes      | Body     | String    | Valid address     | The recipient's wallet address   |
| amount        | Yes      | Body     | Decimal   | Positive value    | The amount of TET to transfer    |

#### Example Request in JSON Format
```json
{
  "session_key": "ipafq343r62RvtD1cw1fSoB5FyPHfVxeeR",
  "to": "0x78a53a1aa4bec431a53e6628fe06d34cb8053599",
  "amount": 1
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter   | Required | Data Type | Description                |
| ----------- | -------- | --------- | -------------------------- |
| hash        | Yes      | String    | The transaction hash       |

#### Example Successful Response
```json
{
  "hash": "ab2463661ed0a5647ddf71ce1546a3adea070b5462afd3ec59d3ff8d750922a4"
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
| VALIDATION_FAILED       | 400 Bad Request   | Incorrect amount                   |

#### Example Error Response
```json
{
  "error": "VALIDATION_FAILED",
  "message": "incorrect amount"
}
```

### Workflow
1. The user sends a transfer request with the session key, recipient address, and amount.
2. If successful, the server returns the transaction hash.
3. If the amount is incorrect (e.g., zero), the server returns an error.
