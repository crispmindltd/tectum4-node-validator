## Purpose
Staking tokens to become a network validator.

### Request Description
- **Method**: POST 
- **URL**: `/tokens/stake`

### Request Parameters
| Parameter         | Required | Location | Data Type | Constraints        | Description                        |
| ----------------- | -------- | -------- | --------- | ------------------ | ---------------------------------- |
| address           | Yes      | Body     | String    | Valid address      | The staking wallet address         |
| amount            | Yes      | Body     | String    | Positive value     | The amount of tokens to stake      |
| private_key       | Yes      | Body     | String    | Valid private key  | The private key of the sender      |
| public_key        | Yes      | Body     | String    | Valid public key   | The public key of the sender       |

#### Example Request in JSON Format
```json
{
  "address": "0x535af33106dcdf40b68348fe227f7bee1347cae6",
  "amount": 400,
  "private_key": "1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d",
  "public_key": "0p0p0p0p0p0p0p0p0p0p0p0p00p0p0p0p0p0p00p0p0p0p0p0p0p0p00p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter   | Required | Data Type | Description                         |
| ----------- | -------- | --------- | ------------------------------------|
| hash        | Yes      | String    | The staking transaction hash        |

#### Example Successful Response
```json
{
  "hash": "22cd6284f17d541e63f39ea033f860f092b15bb871c183f065a9f88556bc0a17"
}
```

### Workflow
1. The user sends a request with the staking wallet address and the amount of tokens to stake.
2. The server verifies the staking transaction and returns a transaction hash if successful.
3. If the signature is invalid, the server returns an error.
