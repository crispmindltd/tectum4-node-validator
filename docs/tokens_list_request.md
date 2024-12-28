
### Purpose
Retrieve a list of all tokens with detailed information such as owner, name, ticker, amount, and more.

### Request Description
- **Method**: GET  
- **URL**: `/tokens`

### Request Parameters

| Parameter  | Required | Location | Data Type | Constraints      | Description                                    |
| ---------- | -------- | -------- | --------- | ----------------| ---------------------------------------------- |
| rows       | Yes      | Query    | Integer   | Positive         | The number of tokens to retrieve in the response|
| skip       | Yes      | Query    | Integer   | Positive         | The number of tokens to skip before returning results|

#### Example Request
```
GET /tokens?rows=1&skip=0
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter    | Required | Data Type | Description                             |
| ------------ | -------- | --------- | --------------------------------------- |
| tokens       | Yes      | Array     | List of tokens with their details       |

Each token entry contains the following:

| Parameter    | Required | Data Type | Description                             |
| ------------ | -------- | --------- | --------------------------------------- |
| id           | Yes      | Integer   | The unique ID of the token              |
| owner_id     | Yes      | Integer   | The ID of the token's owner             |
| name         | Yes      | String    | The name of the token                   |
| date         | Yes      | Integer   | The creation date of the token (timestamp)|
| ticker       | Yes      | String    | The ticker symbol of the token          |
| amount       | Yes      | Integer   | The total supply of the token           |
| decimals     | Yes      | Integer   | The number of decimal places for the token|
| info         | Yes      | String    | A description or information about the token|
| address      | Yes      | String    | The smart contract address of the token |

#### Example Successful Response
```json
{
  "tokens": [
    {
      "id": 2,
      "owner_id": 52482,
      "name": "FocusCoin",
      "date": 1725260888,
      "ticker": "FOCUS",
      "amount": 100000,
      "decimals": 2,
      "info": "FocusCoin is a cryptocurrency for measuring health and performance.",
      "address": "0x1a50b26fc90d84d492c86f633a5f88c070063afc"
    }
  ]
}
```

### Workflow
1. The user sends a request specifying the number of tokens to retrieve and how many to skip.
2. The server returns a list of tokens with their details.
