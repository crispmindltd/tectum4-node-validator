### Purpose
Recover the public, private keys and cryptocurrency address using a provided seed phrase.

### Request Description
- **Method**: POST 
- **URL**: `/keys/recover`

### Request Parameters
| Parameter          | Required | Location | Data Type | Constraints      | Description                        |
| ------------------ | -------- | -------- | --------- | ---------------- | ---------------------------------- |
| seed_phrase        | Yes      | Body     | String    | 12-24 words      | User's seed phrase                 |

#### Example Request in JSON Format
```json
{
    "seed_phrase":"income mind control employ frame nerve that rail heart bleak enforce detail"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter        | Required | Data Type | Description                              |
| ---------------- | -------- | --------- | -----------------------------------------|
| private_key      | Yes      | String    | Recovered private key                    |
| public_key       | Yes      | String    | Recovered public key                     |
| address          | Yes      | String    | Recovered cryptocurrency address         |

#### Example Successful Response
```json
{
  "private_key":"3ed36d3e1032c902ee04b480482cbda44aa5bf355e805acba251cf3cb3456085",
  "public_key":"04f00b2bec485efb4a8cd16f779a56c026e38fadbe64120cec236c50063f8aefef1d9afca2409bda515b27440b821a346993564f8445a8f051fba7a53f2dffd476",
  "address":"0x9396a7f35bfa74e9ab32ccaf10b441b75a2e7329"
}
```

### Workflow
1. The user submits a seed phrase.
2. If valid, the server returns the corresponding public and private keys.
3. If the seed phrase is invalid, the server returns an error.
