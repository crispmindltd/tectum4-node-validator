### Purpose
Get the coin balance by the cryptocurrency address.

### Request Description
- **Method**: GET  
- **URL**: `/coins/balance/byaddress`

### Request Parameters
| Parameter      | Required | Location | Data Type | Constraints                | Description                                      |
| -------------- | -------- | -------- | --------- | -------------------------- | ------------------------------------------------ |
| address        | Yes      | Query    | String    | Valid address (42 words)   | User's cryptocurrency address                    |

#### Example Request
```
GET /coins/balance/byaddress?address=0x9396a7f35bfa74e9ab32ccaf10b441b75a2e7329
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter     | Required | Data Type | Description                                            |
| ------------- | -------- | --------- | ------------------------------------------------------ |
| balance       | Yes      | Integer   | Balance of coins at the cryptocurrency address         |

#### Example Successful Response
```json
{
  "balance": 0
}
```

### Workflow
1. The user sends a request to receive the current coin balance by cryptocurrency address.
2. The server returns the balance of coins at the cryptocurrency address.