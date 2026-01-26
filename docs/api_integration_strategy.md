# ERPNext API Integration Strategy

## 1. Network Stack
- **Library**: `Dio` (Feature-rich HTTP client).
- **Cookie Management**: `dio_cookie_manager` + `persist_cookie_jar`. ERPNext relies heavily on cookies for session management.
- **BaseUrl**: Dynamic, user-inputted. Stored in `SharedPreferences`.

## 2. API Service Abstraction
It is recommended to wrap Dio in a generic `ApiService` class that handles:
- **Base URL Injection**: Interceptor to prepend `server_url` to requests.
- **Error Handling**: Convert `DioException` to user-friendly custom `Failure` objects.
- **Timeouts**: Default 10s connect/receive timeout.

## 3. Recommended Endpoint Mapping

| Feature | ERPNext Endpoint / Method | Notes |
| :--- | :--- | :--- |
| **Login** | `/api/method/login` OR Custom `login()` | Custom method returns roles & details in one go. |
| **Get User** | `/api/method/frappe.auth.get_logged_user` | Used to verify session validity. |
| **Leads List** | `/api/resource/Lead` | Use `fields=["name", "lead_name", ...]` and `filters`. |
| **Create Lead** | `POST /api/resource/Lead` | Send JSON body with mapped fields. |
| **Tasks** | `/api/resource/ToDo` | Filter by `owner` = current user. |

## 4. Role-Based Access Control (RBAC) Approach
- **Fetch Roles**: On Login, store the `roles` list (e.g. `["Sales User", "Manager"]`).
- **Flutter Logic**: Use a `UserProvider` to expose `currentUser`.
- **UI Visibility**:
  ```dart
  if (ref.watch(userProvider).hasRole('Manager'))
    AdminPanelWidget()
  else
    SizedBox()
  ```
- **Backend Enforcement**: ERPNext handles data-level permissions automatically based on the session user.

## 5. Offline Sync Strategy (Phase 2 Consideration)
- **Local DB**: Use `Isar` or `Hive` to cache JSON responses.
- **Queue**: For offline writes (Create Lead), add to a `SyncQueue` and retry when `ConnectivityResult` changes to `connected`.
