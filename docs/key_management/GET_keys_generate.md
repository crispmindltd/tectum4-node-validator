### Purpose
Сreate a new cryptocurrency address based on the key pair and seed phrase.

### Request Description
- **Method**: GET 
- **URL**: `/keys/new`

### Request Parameters
No parameters are required for this request.

#### Example Request
```
GET /keys/new
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter        | Required | Data Type | Description                                              |
| ---------------- | -------- | --------- | -------------------------------------------------------- |
| seed_phrase      | Yes      | String    | Seed phrase to restore access to cryptocurrency address  |
| private_key      | Yes      | String    | Private key of the new cryptocurrency address            |
| public_key       | Yes      | String    | Public key of the new cryptocurrency address             |
| address          | Yes      | String    | New user cryptocurrency address                          |

#### Example Successful Response
```json
{
  "seed_phrase":"income mind control employ frame nerve that rail heart bleak enforce detail",
  "private_key":"3ed36d3e1032c902ee04b480482cbda44aa5bf355e805acba251cf3cb3456085",
  "public_key":"04f00b2bec485efb4a8cd16f779a56c026e38fadbe64120cec236c50063f8aefef1d9afca2409bda515b27440b821a346993564f8445a8f051fba7a53f2dffd476",
  "address":"0x9396a7f35bfa74e9ab32ccaf10b441b75a2e7329"
}
```

### Workflow
1. The user sends a request to generate a new cryptocurrency address.
2. The server returns data from his new cryptocurrency address to him.
