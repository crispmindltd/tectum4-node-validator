
### Purpose
Retrieve the fee required for a coin transfer transaction.

### Request Description
- **Method**: GET  
- **URL**: `/coins/transfer/fee`

### Request Parameters
No parameters are required for this request.

#### Example Request
```
GET /coins/transfer/fee
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter    | Required | Data Type | Description                             |
| ------------ | -------- | --------- | --------------------------------------- |
| fee          | Yes      | Decimal   | The fee for a transfer transaction      |

#### Example Successful Response
```json
{
  "fee": 0
}
```

### Workflow
1. The user sends a request to retrieve the current transfer fee.
2. The server returns the fee value.
