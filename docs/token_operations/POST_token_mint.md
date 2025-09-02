### Purpose
Creating a new token.

### Request Description
- **Method**: POST 
- **URL**: `/token/mint`

### Request Parameters
| Parameter         | Required | Location | Data Type | Constraints                     | Description                                   |
| ----------------- | -------- | -------- | --------- | ------------------------------- | --------------------------------------------- |
| ticker            | Yes      | Body     | String    | Character string (3-8 words)    | Token ticker                                  |
| name              | Yes      | Body     | String    | Character string (3-32 words)   | Full name of the token                        |
| description       | Yes      | Body     | String    | Character string (10-255 words) | Token Description                             |
| iconURL           | Yes      | Body     | String    | Character string (10-128 words) | Link to token icon                            |
| decimals          | Yes      | Body     | Integer   | Positive value (2-8)            | Number of digits after the decimal point      |
| amount            | Yes      | Body     | Integer   | Positive value (1000-10^16)     | Number of tokens                              |
| private_key       | Yes      | Body     | String    | Valid private key (64 words)    | Sender's private key                          |

#### Example Request in JSON Format
```json
{
    "ticker": "TET",
    "name": "Tectum Emission Token",
    "description": "Tectum Token",
    "iconURL": "https://uxwing.com/wp-content/themes/uxwing/download/sport-and-awards/achievement-award-medal-icon.png",
    "decimals": 6,
    "amount": 700000000000000,
    "private_key": "3ed36d3e1032c902ee04b480482cbda44aa5bf355e805acba251cf3cb3456085"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter   | Required | Data Type | Description                         |
| ----------- | -------- | --------- | ------------------------------------|
| hash        | Yes      | String    | Minting transaction hash            |

#### Example Successful Response
```json
{
  "hash": "22cd6284f17d541e63f39ea033f860f092b15bb871c183f065a9f88556bc0a17"
}
```

### Workflow
1. The user sends a request to create a new token.
2. The server verifies the minting transaction and returns a transaction hash if successful.
3. If the signature is invalid, the server returns an error.
