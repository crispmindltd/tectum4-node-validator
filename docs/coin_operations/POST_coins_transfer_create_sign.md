### Purpose
Generating a signed transaction.

### Request Description
- **Method**: POST 
- **URL**: `/coins/transfer/create-sign`

### Request Parameters
| Parameter         | Required | Location | Data Type | Constraints                   | Description                        |
| ----------------- | -------- | -------- | --------- | ----------------------------- | ---------------------------------- |
| from              | Yes      | Body     | String    | Valid address (42 words)      | Sender's cryptocurrency address    |
| to                | Yes      | Body     | String    | Valid address (42 words)      | Recipient's cryptocurrency address |
| amount            | Yes      | Body     | Integer   | Positive value                | Amount of coins to transfer        |
| private_key       | Yes      | Body     | String    | Valid private key (64 words)  | Sender's private key               |

#### Example Request in JSON Format
```json
{
  "from": "0x9396a7f35bfa74e9ab32ccaf10b441b75a2e7329",
  "to": "0x78a53a1aa4bec431a53e6628fe06d34cb8053599",
  "amount": 400,
  "private_key": "3ed36d3e1032c902ee04b480482cbda44aa5bf355e805acba251cf3cb3456085"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter   | Required | Data Type | Description                         |
| ----------- | -------- | --------- | ------------------------------------|
| signed_tx   | Yes      | String    | Signed transaction                  |

#### Example Successful Response
```json
{
  "signed_tx":"a20000000100a2b777d62d60031bab532e9c29b2c26b24df619b00000000469f24000000000000000000000000004a5fb1e7cb4944bd55e63c6e02f7eae590442ac0000000008096980000000000102700000000000085d5a40499010000df5074ec45b00c6cd71175156c275bd50eda4d49140e12a829a1834a923d4acc574ca0b0c22a9f5fece3486bae41ad87e27b96a6985e49a9835034d1daeca7091c00000000000000"
}
```

### Workflow
1. The user sends a request to sign the transaction.
2. The server verifies the transaction and returns a signature if successful.
3. If the signature is invalid, the server returns an error.
