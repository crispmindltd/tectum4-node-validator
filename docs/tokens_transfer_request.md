## Purpose
To transfer tokens between two addresses.

### Request Description
- **Method**: POST 
- **URL**: `/tokens/transfer`

### Request Parameters
| Parameter         | Required | Location | Data Type | Constraints        | Description                        |
| ----------------- | -------- | -------- | --------- | ------------------ | ---------------------------------- |
| from              | Yes      | Body     | String    | Valid address      | The sender's wallet address        |
| to                | Yes      | Body     | String    | Valid address      | The recipient's wallet address     |
| amount            | Yes      | Body     | String    | Positive value     | The amount of tokens to transfer   |
| private_key       | Yes      | Body     | String    | Valid private key  | The private key of the sender      |

#### Example Request in JSON Format
```json
{
  "from": "0x535af33106dcdf40b68348fe227f7bee1347cae6",
  "to": "0x78a53a1aa4bec431a53e6628fe06d34cb8053599",
  "amount": 400,
  "private_key": "1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter   | Required | Data Type | Description                         |
| ----------- | -------- | --------- | ------------------------------------|
| hash        | Yes      | String    | The transaction hash                |

#### Example Successful Response
```json
{
  "hash": "22cd6284f17d541e63f39ea033f860f092b15bb871c183f065a9f88556bc0a17"
}
```

### Workflow
1. The user sends a request with the sender's wallet address, recipient's wallet address and the amount of tokens to transfer.
2. The server verifies the transaction and returns a transaction hash if successful.
3. If the signature is invalid, the server returns an error.
