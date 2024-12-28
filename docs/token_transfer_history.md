
### Purpose
Retrieve the transfer history for a specific token.

### Request Description
- **Method**: GET  
- **URL**: `/tokens/transfers`

### Request Parameters

| Parameter    | Required | Location | Data Type | Constraints      | Description                                    |
| ------------ | -------- | -------- | --------- | ----------------| ---------------------------------------------- |
| rows         | Yes      | Query    | Integer   | Positive         | The number of transactions to retrieve         |
| skip         | Yes      | Query    | Integer   | Positive         | The number of transactions to skip before returning results |
| ticker       | Yes      | Query    | String    | Valid ticker     | The ticker symbol of the token                 |

#### Example Request
```
GET /tokens/transfers?rows=5&skip=0&ticker=FOCUS
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter       | Required | Data Type | Description                             |
| --------------- | -------- | --------- | --------------------------------------- |
| ticker          | Yes      | String    | The ticker symbol of the token          |
| transactions    | Yes      | Array     | List of token transfer transactions     |

Each transaction entry contains the following:

| Parameter       | Required | Data Type | Description                             |
| --------------- | -------- | --------- | --------------------------------------- |
| date            | Yes      | Integer   | The timestamp of the transaction        |
| block           | Yes      | Integer   | The block number of the transaction     |
| address_from    | Yes      | String    | The sender's address                    |
| address_to      | Yes      | String    | The recipient's address                 |
| hash            | Yes      | String    | The transaction hash                    |
| amount          | Yes      | Decimal   | The amount of tokens transferred        |
| fee             | Yes      | Decimal   | The transaction fee                     |

#### Example Successful Response
```json
{
  "ticker": "FOCUS",
  "transactions": [
    {
      "date": 1725260889,
      "block": 0,
      "address_from": "0x1a50b26fc90d84d492c86f633a5f88c070063afc",
      "address_to": "0x1a50b26fc90d84d492c86f633a5f88c070063afc",
      "hash": "30a21800b76c9569c76f321ec4a11800a0a218001074c477c76f321ed4a11800",
      "amount": 0,
      "fee": 0
    }
  ]
}
```

### Error Response
#### Common Error Response Structure

| Parameter | Required | Data Type | Description          |
| --------- | -------- | --------- | -------------------- |
| error     | Yes      | String    | Error code           |
| message   | Yes      | String    | Error description    |

### Error Codes

| Error Code                  | HTTP Status Code  | Error Description                  |
| --------------------------- | ----------------- | ---------------------------------- |
| SMARTCONTRACT_NOT_EXISTS     | 400 Bad Request   | The specified smart contract does not exist|

#### Example Error Response
```json
{
  "error": "SMARTCONTRACT_NOT_EXISTS",
  "message": "smart contract does not exists"
}
```

### Workflow
1. The user sends a request specifying the number of transactions to retrieve, how many to skip, and the token ticker.
2. The server returns the transfer history for the specified token.
3. If the ticker is invalid or the smart contract doesn't exist, the server returns an error.
