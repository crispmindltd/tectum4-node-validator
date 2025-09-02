### Purpose
Getting token information by ticker.

### Request Description
- **Method**: GET  
- **URL**: `/token/info`

### Request Parameters
| Parameter      | Required | Location | Data Type | Constraints                  | Description                     |
| -------------- | -------- | -------- | --------- | ---------------------------- | ------------------------------- |
| ticker         | Yes      | Query    | String    | Character string (3-8 words) | Token ticker                    |

#### Example Request
```
GET /token/info?ticker=TET
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter     | Required | Data Type | Description                                      |
| ------------- | -------- | --------- | -------------------------------------------------|
| id            | Yes      | Integer   | Blockchain token ID                              |
| name          | Yes      | String    | Full name of the token                           |
| ticker        | Yes      | String    | Token ticker                                     |
| description   | Yes      | String    | Token Description                                |
| iconURL       | Yes      | String    | Link to token icon                               |
| ownerAddress  | Yes      | String    | Cryptocurrency address of the token creator      |
| decimals      | Yes      | Integer   | Number of digits after the decimal point         |

#### Example Successful Response
```json
{
    "id":1,
    "name":"Tectum Emission Token",
    "ticker":"TET",
    "description":"Tectum Token",
    "iconURL":"https://uxwing.com/wp-content/themes/uxwing/download/sport-and-awards/achievement-award-medal-icon.png",
    "ownerAddress":"a2b777d62d60031bab532e9c29b2c26b24df619b",
    "decimals":6
}
```

### Workflow
1. The user sends a request to receive information about the token by ticker.
2. The server returns information about the token.