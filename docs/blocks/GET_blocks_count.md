### Purpose
Get the total number of blocks in the blockchain.

### Request Description
- **Method**: GET  
- **URL**: `/blockscount`

### Request Parameters
No parameters are required for this request.

#### Example Request
```
GET /blockscount
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter     | Required | Data Type | Description                             |
| ------------- | -------- | --------- | --------------------------------------- |
| blocksCount   | Yes      | Integer   | Total number of blocks                  |

#### Example Successful Response
```json
{
  "blocksCount": 1
}
```

### Workflow
1. The user sends a request to retrieve the current block count.
2. The server returns the total number of blocks in the blockchain.