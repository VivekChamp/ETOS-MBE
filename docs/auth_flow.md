# Auth & Session Flow Diagram (Textual)

## 1. Login Process
```mermaid
sequenceDiagram
    participant User
    participant App (Flutter)
    participant LocalStorage
    participant ERPNext (API)

    User->>App: Enters URL, Username, Password
    App->>App: Validates Inputs
    App->>ERPNext: POST /api/method/login (or custom login)
    Note right of App: Payload: {usr, pwd}
    
    alt Success
        ERPNext-->>App: 200 OK + JSON (sid, rules, user_info)
        Note right of ERPNext: Set-Cookie: sid=...
        App->>LocalStorage: Save 'sid' (cookie)
        App->>LocalStorage: Save 'server_url'
        App->>LocalStorage: Save 'user_role'
        App->>User: Navigate to Dashboard
    else Failure
        ERPNext-->>App: 401 Unauthorized / 417 Expectation Failed
        App->>User: Show Error Popup
    end
```

## 2. Session Management
- **Token**: ERPNext uses `sid` (Session ID) in cookies.
- **Persistence**: `cookie_jar` manages cookies. `PersistCookieJar` saves them to device storage.
- **Expiry Checking**:
  - Global Dio Interceptor checks for `401` or `403` responses.
  - If `401` detected -> Clear LocalStorage & Redirect to Login.

## 3. Auto-Login
- On App Start -> Check if `sid` cookie exists in `PersistCookieJar`.
- If yes -> Attempt simple API call (e.g. `get_logged_in_user`).
- If success -> Go to Dashboard.
- If failure (401) -> Go to Login.
