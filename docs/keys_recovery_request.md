## Purpose
Recover the public, private keys and crypto address using a provided seed phrase.

### Request Description
- **Method**: POST 
- **URL**: `/keys/recover`

### Request Parameters
| Parameter          | Required | Location | Data Type | Constraints      | Description                        |
| ------------------ | -------- | -------- | --------- | ---------------- | ---------------------------------- |
| seed_phrase        | Yes      | Body     | String    | 12-24 words      | The user's seed phrase             |

#### Example Request in JSON Format
```json
{
    "seed_phrase":"test test test test test test test test test test test test"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter        | Required | Data Type | Description                              |
| ---------------- | -------- | --------- | -----------------------------------------|
| private_key      | Yes      | String    | The recovered private key                |
| public_key       | Yes      | String    | The recovered public key                 |
| address          | Yes      | String    | The recovered crypto address             |

#### Example Successful Response
```json
{
  "private_key":"1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d",
  "public_key":"0p0p0p0p0p0p0p0p0p0p0p0p00p0p0p0p0p0p00p0p0p0p0p0p0p0p00p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0",
  "address":"0xp0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0p0"
}
```

### Workflow
1. The user submits a seed phrase.
2. If valid, the server returns the corresponding public and private keys.
3. If the seed phrase is invalid, the server returns an error.
