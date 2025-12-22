### Purpose
Burn a liquidity token.

### Request Description
- **Method**: POST 
- **URL**: `/token/burn`

### Request Parameters
| Parameter         | Required | Location | Data Type | Constraints                     | Description                                   |
| ----------------- | -------- | -------- | --------- | ------------------------------- | --------------------------------------------- |
| amount            | Yes      | Body     | Integer   | Positive value (1000-10^16)     | Number of tokens                              |
| ticker            | Yes      | Body     | String    | Character string (3-8 words)    | Token ticker                                  |
| private_key       | Yes      | Body     | String    | Valid private key (64 words)    | Sender's private key                          |

#### Example Request in JSON Format
```json
{
    "ticker": "TEST",
    "amount": 700000000000000,
    "private_key": "3ed36d3e1032c902ee04b480482cbda44aa5bf355e805acba251cf3cb3456085"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter   | Required | Data Type | Description                         |
| ----------- | -------- | --------- | ------------------------------------|
| hash        | Yes      | String    | Burning transaction hash            |

#### Example Successful Response
```json
{
  "hash": "22cd6284f17d541e63f39ea033f860f092b15bb871c183f065a9f88556bc0a17"
}
```

### Workflow
1. The user sends a request to burn a liquidity token.
2. The server verifies the burning transaction and returns a transaction hash if successful.
3. If the signature is invalid, the server returns an error.
