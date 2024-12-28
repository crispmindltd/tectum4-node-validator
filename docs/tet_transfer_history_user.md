
### Purpose
Retrieve the TET transfer history for a specific user.

### Request Description
- **Method**: GET  
- **URL**: `/coins/transfers/user`

### Request Parameters

| Parameter  | Required | Location | Data Type | Constraints      | Description                                    |
| ---------- | -------- | -------- | --------- | ----------------| ---------------------------------------------- |
| rows       | Yes      | Query    | Integer   | Positive         | The number of transactions to retrieve in the response|
| skip       | Yes      | Query    | Integer   | Positive         | The number of transactions to skip before returning results|
| user_id    | Yes      | Query    | Integer   | Positive         | The user ID for which the transaction history is requested|

#### Example Request
```
GET /coins/transfers/user?rows=20&skip=0&user_id=52481
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter       | Required | Data Type | Description                             |
| --------------- | -------- | --------- | --------------------------------------- |
| transactions    | Yes      | Array     | List of transactions with their details |

Each transaction entry contains the following:

| Parameter    | Required | Data Type | Description                             |
| ------------ | -------- | --------- | --------------------------------------- |
| date         | Yes      | Integer   | The timestamp of the transaction        |
| block        | Yes      | Integer   | The block number of the transaction     |
| address      | Yes      | String    | The recipient/sender address            |
| incoming     | Yes      | Boolean   | Indicates whether the transaction is incoming or outgoing |
| hash         | Yes      | String    | The transaction hash                    |
| amount       | Yes      | Decimal   | The amount transferred                  |
| fee          | Yes      | Decimal   | The transaction fee                     |

#### Example Successful Response
```json
{
  "transactions": [
    {
      "date": 1717072074,
      "block": 184178,
      "address": "0x0fb033dc191f5b379d7aefceadac9e342c53b9fe",
      "incoming": false,
      "hash": "e9ddc276986e2bf79d9f96520cd31e9827b06e726564361eae25358d0c6696af",
      "amount": 0.00077335,
      "fee": 0
    }
  ]
}
```

### Workflow
1. The user sends a request specifying the number of transactions to retrieve, how many to skip, and the user ID.
2. The server returns a list of transactions for the specified user.
