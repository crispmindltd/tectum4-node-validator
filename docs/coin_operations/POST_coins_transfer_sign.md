### Purpose
Sending a signed transaction to the network.

### Request Description
- **Method**: POST 
- **URL**: `/coins/transfer/sign`

### Request Parameters
| Parameter         | Required | Location | Data Type | Constraints                   | Description                        |
| ----------------- | -------- | -------- | --------- | ----------------------------- | ---------------------------------- |
| signed_tx         | Yes      | Body     | String    | Valid signature (332 words)   | Signed transaction                 |

#### Example Request in JSON Format
```json
{
  "signed_tx":"a20000000100a2b777d62d60031bab532e9c29b2c26b24df619b00000000469f24000000000000000000000000004a5fb1e7cb4944bd55e63c6e02f7eae590442ac0000000008096980000000000102700000000000085d5a40499010000df5074ec45b00c6cd71175156c275bd50eda4d49140e12a829a1834a923d4acc574ca0b0c22a9f5fece3486bae41ad87e27b96a6985e49a9835034d1daeca7091c00000000000000"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter   | Required | Data Type | Description                         |
| ----------- | -------- | --------- | ------------------------------------|
| hash        | Yes      | String    | Transaction hash                    |

#### Example Successful Response
```json
{
  "hash": "0c5a418ece39aed412c000fa0ab491a4c859113ce1bca7c44f3eb5fe30914ebb"
}
```

### Workflow
1. The user sends a request with a signed transaction to the network.
2. The server verifies the transaction and returns a transaction hash if successful.
3. If the signature is invalid, the server returns an error.
