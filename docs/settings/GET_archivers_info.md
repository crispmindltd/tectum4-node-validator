### Purpose
Getting information about archivers.

### Request Description
- **Method**: GET 
- **URL**: `/net`

### Request Parameters
No parameters are required for this request.

#### Example Request
```
GET /net
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter    | Required | Data Type | Description                                |
| ------------ | -------- | --------- | ------------------------------------------ |
| name         | Yes      | String    | Archiver name                              |
| state        | Yes      | String    | Archiver status                            |

#### Example Successful Response
```json
{
    "servers": [
        {"name":"arch12.test.open.tectum.io","state":"passed"},
        {"name":"arch5.test.open.tectum.io","state":"passed"},
        {"name":"arch1.test.open.tectum.io","state":"passed"},
        {"name":"arch3.test.open.tectum.io","state":"passed"},
        {"name":"arch8.test.open.tectum.io","state":"passed"},
        {"name":"arch10.test.open.tectum.io","state":"passed"},
        {"name":"arch6.test.open.tectum.io","state":"passed"},
        {"name":"arch7.test.open.tectum.io","state":"passed"},
        {"name":"arch4.test.open.tectum.io","state":"passed"},
        {"name":"arch9.test.open.tectum.io","state":"passed"},
        {"name":"arch2.test.open.tectum.io","state":"passed"}
    ],
    "clients":[]
}
```

### Workflow
1. The user sends a request to receive information about archivers.
2. The server returns information about them to him.
