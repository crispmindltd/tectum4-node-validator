
## Purpose
To register a new user in the system.

### Request Description
- **Method**: POST  
- **URL**: `/user/registration`

### Request Parameters

| Parameter    | Required | Location | Data Type | Constraints      | Description                     |
| ------------ | -------- | -------- | --------- | ---------------- | ------------------------------- |
| login        | Yes      | Body     | String    | Email format     | User login (email)              |
| password     | Yes      | Body     | String    | 8-64 characters  | User password                   |
| seed_phrase  | Yes      | Body     | String    | 12-24 words      | Seed phrase for the wallet      |

#### Example Request in JSON Format
```json
{
  "login": "user@example.com",
  "password": "password123",
  "seed_phrase": "decide glance clump secret dentist wage hurry garment sentence solar pond host"
}
```

### Response Parameters

#### Successful Response
- **HTTP Status Code**: 200 OK

| Parameter    | Required | Data Type | Description                   |
| ------------ | -------- | --------- | ----------------------------- |
| client_ID    | Yes      | Integer   | The unique ID for the new user|
| seed_phrase  | Yes      | String    | The seed phrase used          |
| login        | Yes      | String    | The login of the user         |
| password     | Yes      | String    | The password of the user      |
| address      | Yes      | String    | The user's wallet address     |
| private_key  | Yes      | String    | The user's private key        |
| public_key   | Yes      | String    | The user's public key         |

#### Example Successful Response
```json
{
  "client_ID": 61727,
  "seed_phrase": "decide glance clump secret dentist wage hurry garment sentence solar pond host",
  "login": "0x8b9e61ccc987b09bc7ecd3643baa353fbddcc66b@softnote.com",
  "password": "676206244",
  "address": "0x8b9e61ccc987b09bc7ecd3643baa353fbddcc66b",
  "private_key": "67ef6c9dfa61ec6643df3da5f67815a48a8153309744cf348d86bba1c012bfd4",
  "public_key": "040d8cd3d5bb22250255d29d610a9f302cc057f6a8367b7988592fdebac29ffaf6ec8b86e8fdb7f060da4766dc8b9e61ccc987b09bc7ecd3643baa353fbddcc66b"
}
```

### Error Response
#### Common Error Response Structure

| Parameter | Required | Data Type | Description          |
| --------- | -------- | --------- | -------------------- |
| error     | Yes      | String    | Error code           |
| message   | Yes      | String    | Error message        |

### Workflow
1. The user sends a registration request with their login, password, and seed phrase.
2. The server creates a new user and returns details including the client ID, keys, and wallet address.
