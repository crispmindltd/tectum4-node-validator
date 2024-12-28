## Purpose
Get your node version.

### Request Description
- **Method**: GET 
- **URL**: `/version`

### Request Parameters
No parameters are required for this request.

#### Example Request in JSON Format
```
GET /version
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter    | Required | Data Type | Description                                |
| ------------ | -------- | --------- | ------------------------------------------ |
| version      | Yes      | String    | The version of the node the user is using  |

#### Example Successful Response
```json
{
  "version":"v4.0.100"
}
```

### Workflow
1. The user sends a request to check the version of his node.
2. The server returns the version value to him.
