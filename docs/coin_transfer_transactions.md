
## Purpose
Retrieve a list of coin transfer transactions for a user based on the session key and the amount of transactions to retrieve.

### Request Description
- **Method**: GET  
- **URL**: `/coins/transfers`

### Request Parameters

| Parameter      | Required | Location | Data Type | Constraints     | Description                                |
| -------------- | -------- | -------- | --------- | --------------- | ------------------------------------------ |
| session_key    | Yes      | Query    | String    | Valid session key | The session key of the user                |
| amount         | Yes      | Query    | Integer   | Positive value   | The number of transactions to retrieve     |

#### Example Request
GET /coins/transfers?session_key=ipaflwecwb7jxe8kecajpkpqkltxx3uvle&amount=5

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter | Required | Data Type | Description                                                      |
| --------- | -------- | --------- | ---------------------------------------------------------------- |
| history   | Yes      | Array     | List of transaction history entries                              |

Each entry in the `history` array contains the following:

| Parameter     | Required | Data Type | Description                                        |
| ------------- | -------- | --------- | -------------------------------------------------- |
| blocknumber   | Yes      | Integer   | Block number in which the transaction occurred     |
| time          | Yes      | String    | Timestamp of the transaction                       |
| tokenfar      | Yes      | String    | Token identifier (address) involved in the transaction |
| transfersum   | Yes      | Decimal   | Amount of coins transferred                        |
| direction     | Yes      | Integer   | Direction of the transfer (1 for outgoing, 2 for incoming) |
| hash          | Yes      | String    | Transaction hash                                   |
| amount        | Yes      | Decimal   | Remaining balance after transaction                |

#### Example Successful Response
```json
{
  "history": [
    {
      "blocknumber": 191131,
      "time": "29.08.2024 03:17:20",
      "tokenfar": "0xf38197a7d346702991d712f2850173f2328643ae",
      "transfersum": 0.5,
      "direction": 2,
      "hash": "fab48c2272cec5c7ca6415f9ed98c9dd5ea3be211141c8d801ec90780e639bc7",
      "amount": 3.999
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

| Error Code         | HTTP Status Code | Error Description                  |
| ------------------ | ---------------- | ---------------------------------- |
| validation_failed  | 400 Bad Request  | Invalid amount value provided      |

#### Example Error Response
```json
{
  "error": "validation_failed",
  "message": "invalid amount value"
}
```

### Workflow
1. The user sends a request with the session key and the number of transactions to retrieve.
2. The server returns a history of the requested transactions.
3. If the request is invalid (e.g., `amount = 0`), the server returns an error.
