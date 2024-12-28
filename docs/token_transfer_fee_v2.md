
### Purpose
Retrieve the fee required for transferring a token.

### Request Description
- **Method**: GET  
- **URL**: `/tokens/transfer/fee`

### Request Parameters
No parameters are required for this request.

#### Example Request
```
GET /tokens/transfer/fee
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter    | Required | Data Type | Description                             |
| ------------ | -------- | --------- | --------------------------------------- |
| fee          | Yes      | Decimal   | The fee for the token transfer          |

#### Example Successful Response
```json
{
  "fee": 0
}
```

### Workflow
1. The user sends a request to retrieve the token transfer fee.
2. The server returns the fee value.
