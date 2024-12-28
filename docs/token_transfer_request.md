
## Purpose
To transfer tokens between two addresses using a smart contract.

### Request Description
- **Method**: POST  
- **URL**: `/tokens/transfer`

### Request Parameters

| Parameter      | Required | Location | Data Type | Constraints       | Description                            |
| -------------- | -------- | -------- | --------- | ----------------- | -------------------------------------- |
| from           | Yes      | Body     | String    | Valid address     | The sender's wallet address            |
| to             | Yes      | Body     | String    | Valid address     | The recipient's wallet address         |
| smart_address  | Yes      | Body     | String    | Valid address     | The smart contract address             |
| amount         | Yes      | Body     | Decimal   | Positive value    | The amount of tokens to transfer       |
| private_key    | Yes      | Body     | String    | Valid private key | The private key of the sender          |
| public_key     | Yes      | Body     | String    | Valid public key  | The public key of the sender           |

#### Example Request in JSON Format
```json
{
  "from": "0x535af33106dcdf40b68348fe227f7bee1347cae6",
  "to": "0x78a53a1aa4bec431a53e6628fe06d34cb8053599",
  "smart_address": "0x4752cbb6b5f0d60b816188163f35d4128da9fa75",
  "amount": 400,
  "private_key": "4c547e137bb4ae7b8bb81171359583054b2db19c82bd7beba803c6ae5f840165",
  "public_key": "04e8ec7f7aff597b56b1f0c23a6642e393d32a015bd15e369b1d0234948322940613a49ecee827983d7e5b38c5535af33106dcdf40b68348fe227f7bee1347cae6"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter   | Required | Data Type | Description                |
| ----------- | -------- | --------- | -------------------------- |
| hash        | Yes      | String    | The transaction hash       |

#### Example Successful Response
```json
{
  "hash": "22cd6284f17d541e63f39ea033f860f092b15bb871c183f065a9f88556bc0a17"
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
| INVALID_SIGN            | 400 Bad Request   | Signature not verified             |

#### Example Error Response
```json
{
  "error": "INVALID_SIGN",
  "message": "signature not verified"
}
```

### Workflow
1. The user sends a request with the sender's wallet address, recipient's wallet address, smart contract address, and the amount of tokens to transfer.
2. The server verifies the transaction and returns a transaction hash if successful.
3. If the signature is invalid, the server returns an error.
