
## Purpose
Retrieve the balance of a token for a given address by using the token's ticker.

### Request Description
- **Method**: GET  
- **URL**: `/tokens/balance/byticker`

### Request Parameters

| Parameter      | Required | Location | Data Type | Constraints   | Description                                      |
| -------------- | -------- | -------- | --------- | ------------- | ------------------------------------------------ |
| address_tet    | Yes      | Query    | String    | Valid address | The address of the TET wallet                     |
| ticker         | Yes      | Query    | String    | Valid ticker  | The ticker symbol of the token                    |

#### Example Request
GET /tokens/balance/byticker?address_tet=0x535af33106dcdf40b68348fe227f7bee1347cae6&ticker=kar

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter | Required | Data Type | Constraints    | Description                          |
| --------- | -------- | --------- | -------------- | ------------------------------------ |
| balance   | Yes      | Decimal   | Positive value | The token balance for the address    |

#### Example Successful Response
```json
{
  "balance": 995.0
}
```

### Error Response
#### Common Error Response Structure

| Parameter | Required | Data Type | Description          |
| --------- | -------- | --------- | -------------------- |
| error     | Yes      | String    | Error code           |
| message   | Yes      | String    | Error description    |

### Error Codes

| Error Code               | HTTP Status Code  | Error Description                |
| ------------------------ | ----------------- | -------------------------------- |
| SMARTCONTRACT_NOT_EXISTS  | 400 Bad Request   | The smart contract does not exist|

#### Example Error Response
```json
{
  "error": "SMARTCONTRACT_NOT_EXISTS",
  "message": "smart contract does not exists"
}
```

### Workflow
1. The user sends a request with the wallet address and token ticker.
2. The server returns the balance if the ticker is valid.
3. If the ticker doesn't exist, the server returns an error.
