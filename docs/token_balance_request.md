
## Purpose
Retrieve the balance of a token for a given address by using the token's smart contract address.

### Request Description
- **Method**: GET  
- **URL**: `/tokens/balance/byaddress`

### Request Parameters

| Parameter      | Required | Location | Data Type | Constraints   | Description                                      |
| -------------- | -------- | -------- | --------- | ------------- | ------------------------------------------------ |
| address_tet    | Yes      | Query    | String    | Valid address | The address of the TET wallet                     |
| smart_address  | Yes      | Query    | String    | Valid address | The smart contract address of the token           |

#### Example Request
GET /tokens/balance/byaddress?address_tet=0x535af33106dcdf40b68348fe227f7bee1347cae6&smart_address=0x4752cbb6b5f0d60b816188163f35d4128da9fa75

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter | Required | Data Type | Constraints    | Description                          |
| --------- | -------- | --------- | -------------- | ------------------------------------ |
| balance   | Yes      | Decimal   | Positive value | The token balance for the address    |

#### Example Successful Response
```json
{
  "balance": 987.939
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
1. The user sends a request with the wallet address and smart contract address.
2. The server returns the balance if the smart contract exists.
3. If the smart contract doesn't exist, the server returns an error.
