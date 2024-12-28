
## Purpose
To create a new token with specified parameters.

### Request Description
- **Method**: POST  
- **URL**: `/tokens`

### Request Parameters

| Parameter       | Required | Location | Data Type | Constraints         | Description                      |
| --------------- | -------- | -------- | --------- | ------------------- | -------------------------------- |
| session_key     | Yes      | Body     | String    | Valid session key   | The session key of the user      |
| full_name       | Yes      | Body     | String    | None                | The full name of the token       |
| short_name      | Yes      | Body     | String    | None                | The short name of the token      |
| ticker          | Yes      | Body     | String    | Unique ticker       | The token ticker symbol          |
| token_amount    | Yes      | Body     | Integer   | Positive value      | The total amount of tokens       |
| decimals        | Yes      | Body     | Integer   | 0-8                 | The number of decimals for the token|

#### Example Request in JSON Format
```json
{
  "session_key": "ipamBTvFbfM7AVlAa9ThnFJuah7whCLPTL",
  "full_name": "testdonttouch100",
  "short_name": "testdonttouch",
  "ticker": "tdon",
  "token_amount": 10000,
  "decimals": 8
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter          | Required | Data Type | Description                                |
| ------------------ | -------- | --------- | ------------------------------------------ |
| transaction_hash   | Yes      | String    | The transaction hash for the token creation|
| smartcontract_ID   | Yes      | Integer   | The unique ID of the smart contract        |

#### Example Successful Response
```json
{
  "transaction_hash": "0x535af33106dcdf40b68348fe227f7bee1347cae6",
  "smartcontract_ID": 25
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
| VALIDATION_FAILED       | 400 Bad Request   | Invalid decimals value             |

#### Example Error Response
```json
{
  "error": "VALIDATION_FAILED",
  "message": "invalid decimals value"
}
```

### Workflow
1. The user submits a request to create a token with the full name, short name, ticker, and other parameters.
2. The server validates the request and creates the token.
3. If successful, the server returns the transaction hash and smart contract ID.
4. If the request is invalid, the server returns an error.
