### Purpose
Request to withdraw funds from staking.

### Request Description
- **Method**: POST 
- **URL**: `/coins/unstake`

### Request Parameters
| Parameter         | Required | Location | Data Type | Constraints                   | Description                        |
| ----------------- | -------- | -------- | --------- | ----------------------------- | ---------------------------------- |
| address           | Yes      | Body     | String    | Valid address (42 words)      | Staking cryptocurrency address     |
| amount            | Yes      | Body     | Integer   | Positive value                | Amount of coins to unstake         |
| private_key       | Yes      | Body     | String    | Valid private key (64 words)  | Sender's private key               |

#### Example Request in JSON Format
```json
{
    "address": "0x535af33106dcdf40b68348fe227f7bee1347cae6",
    "amount": 100,
    "private_key": "3ed36d3e1032c902ee04b480482cbda44aa5bf355e805acba251cf3cb3456085"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter   | Required | Data Type | Description                         |
| ----------- | -------- | --------- | ------------------------------------|
| hash        | Yes      | String    | Unstaking transaction hash          |

#### Example Successful Response
```json
{
  "hash": "22cd6284f17d541e63f39ea033f860f092b15bb871c183f065a9f88556bc0a17"
}
```

### Workflow
1. The user sends a request with the staking cryptocurrency address and the amount of coins to withdraw funds from staking.
2. The server verifies the unstaking transaction and returns a transaction hash if successful.
3. If the signature is invalid, the server returns an error.
