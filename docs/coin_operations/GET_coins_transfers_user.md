### Purpose
Get a certain amount of transactions for a cryptocurrency address.

### Request Description
- **Method**: GET 
- **URL**: `/coins/transfers/user`

### Request Parameters
| Parameter      | Required | Location | Data Type | Constraints                | Description                                      |
| -------------- | -------- | -------- | --------- | -------------------------- | ------------------------------------------------ |
| row            | Yes      | Query    | Integer   | Positive value             | Number of transactions                           |
| address        | Yes      | Query    | String    | Valid address (42 words)   | User's cryptocurrency address                    |

#### Example Request
```
GET /coins/transfers/user?row=20&skip=0&address=0xe19e5829389d9dc5731fb807dde6de3fbe3d5a11
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter        | Required | Data Type | Description                                      |
| ---------------- | -------- | --------- | ------------------------------------------------ |
| block            | Yes      | Integer   | Transaction block number                         |
| hash             | Yes      | String    | Transaction hash                                 |
| type             | Yes      | String    | Transaction type                                 |
| date             | Yes      | Integer   | Transaction date                                 |
| address_from     | Yes      | String    | Sender's cryptocurrency address                  |
| address_to       | Yes      | String    | Recipient's cryptocurrency addres                |
| amount           | Yes      | Integer   | Amount of coins to transfer                      |
| fee              | Yes      | Integer   | Transaction fee                                  |


#### Example Successful Response
```json
{
  "transactions":[
    {
      "block":1118,
      "hash":"bfb33a6535ce6c4a591e5a443644827dff8f4ea3b3d101e319ad606b700f11f3",
      "type":"transfer",
      "date":1741339482,
      "address_from":"0xe19e5829389d9dc5731fb807dde6de3fbe3d5a11",
      "address_to":"0x16d2d76f20a33f797546eb4b45d0049486fbdbb6",
      "amount":300000,
      "fee":10000
    },{
      "block":1117,
      "hash":"62cadb946946472c6fa7f00a027bbf392ee376f2015fd90a88606c621ef2afa2",
      "type":"stake",
      "date":1741339126,
      "address_from":"0xe19e5829389d9dc5731fb807dde6de3fbe3d5a11",
      "address_to":"0xe19e5829389d9dc5731fb807dde6de3fbe3d5a11",
      "amount":8000000,
      "fee":10000
    },{
      "block":1116,
      "hash":"20abd8e2d1fa13f2411f6eb461a1a377e4c123bcc1526a53dcd7c59426de5c02",
      "type":"stake",
      "date":1741339120,
      "address_from":"0xe19e5829389d9dc5731fb807dde6de3fbe3d5a11",
      "address_to":"0xe19e5829389d9dc5731fb807dde6de3fbe3d5a11",
      "amount":8000000,
      "fee":10000
    }
  ]
}
```

### Workflow
1. The user sends a request to receive a certain number of user transactions to the cryptocurrency address.
2. The server provides the user with data on transactions.
