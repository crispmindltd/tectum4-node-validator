### Purpose
Get coin transaction information by block ID.

### Request Description
- **Method**: GET 
- **URL**: `/coins/transfer`

### Request Parameters
| Parameter      | Required | Location | Data Type | Constraints     | Description                                      |
| -------------- | -------- | -------- | --------- | --------------- | ------------------------------------------------ |
| id             | Yes      | Query    | Integer   | Positive value  | Block ID                                         |

#### Example Request
```
GET /coins/transfer?id=1
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter        | Required | Data Type | Description                                      |
| ---------------- | -------- | --------- | ------------------------------------------------ |
| hash             | Yes      | String    | Transaction hash                                 |
| type             | Yes      | String    | Transaction type                                 |
| token_id         | Yes      | Integer   | Token ID                                         |
| block            | Yes      | Integer   | Transaction block number                         |
| date             | Yes      | Integer   | Transaction date                                 |
| sign             | Yes      | String    | Transaction signature                            |
| sender_address   | Yes      | String    | Sender's cryptocurrency address                  |
| sender_pubkey    | Yes      | String    | Sender's public key                              |
| prev_hash        | Yes      | String    | Hash of the previous transaction                 |
| receiver_address | Yes      | String    | Recipient's cryptocurrency address               |
| amount           | Yes      | Integer   | Amount of coins to transfer                      |
| fee              | Yes      | Integer   | Transaction fee                                  |


#### Example Successful Response
```json
{
  "hash":"38235722932E740B02CAA9CCC3BA64019578765F28874EB17EEBA534D20CBE14",
  "type":"txSend",
  "token_id":0,
  "block":1,
  "date":1738306713,"sign":"0030450221009A3D7431EFAC5F357E57D66E786069C2C467A6FC10232C59E5D9EE7C58CB3C7902201D8E8277D4DA119463F2AB491289E9BA37CAB65E07131A4F326D3C1EB5D79440","sender_address":"53183586423EAA99F26D1222B0D08E1E6185189C","sender_pubkey":"048E8E50E6C5993BAFB9C9032CE51DB0A7A8514C5553E1C1BE0B6F4665446A45A4100C22AFA5AA4EB26B8D279ADECBB62992B1D8AEF0E54CDF7A285E3C97ED3658","prev_hash":"BE0F5B011F29816A419090E7B9D8A44FADDF9DCDF839A7E8F212422DD5ACE18F",
  "receiver_address":"4AD89FB09DB175400CBB23A13EB993B3B3F50767",
  "amount":100000000000,
  "fee":0
}
```

### Workflow
1. The user sends a request specifying the block ID in the request.
2. The server examines the chain of transaction blocks and after finding the required block, it will return the transaction data.
