### Purpose
Migration of coins from one network to another.

### Request Description
- **Method**: POST 
- **URL**: `/coins/migrate`

### Request Parameters
| Parameter         | Required | Location | Data Type | Constraints                   | Description                        |
| ----------------- | -------- | -------- | --------- | ----------------------------- | ---------------------------------- |
| from              | Yes      | Body     | String    | Valid address (42 words)      | Sender's cryptocurrency address    |
| to                | Yes      | Body     | String    | Valid address (42 words)      | Migration cryptocurrency address   |
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
| hash        | Yes      | String    | Transaction hash                    |

#### Example Successful Response
```json
{
  "hash": "0c5a418ece39aed412c000fa0ab491a4c859113ce1bca7c44f3eb5fe30914ebb"
}
```

### Workflow
1. The user sends a request with the sender's cryptocurrency address, recipient's cryptocurrency address and the amount of coins to migrate.
2. The server verifies the transaction and returns a transaction hash if successful.
3. If the signature is invalid, the server returns an error.
