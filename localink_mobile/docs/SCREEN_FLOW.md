# Screen Flow & Navigation: Localink Mobile App

## 1. Complete Navigation Map

Below is the conceptual screen map of the application showing how routes transition based on authorization states and user roles:

```mermaid
graph TD
    %% Base Screens
    Splash[/splash] --> Welcome{/welcome}
    
    %% Welcome Choice Redirects
    Welcome -->|Selected: User| LoginUser[/login]
    Welcome -->|Selected: Business| LoginOwner[/login]
    Welcome -->|Selected: Admin| LoginAdmin[/login]
    Welcome -->|Skip Button| Home[/home]

    %% Authentication Path
    LoginUser & LoginOwner --> SignUp[/signup]
    LoginUser & LoginOwner & LoginAdmin --> Forgot[Forgot Password]
    Forgot --> OTP[Verify OTP]
    OTP --> Reset[Reset Password]
    Reset --> LoginUser

    %% Role Screens
    LoginUser -->|Role: User| MainShell[/home, /favorites, /profile, /ai-assistant]
    LoginOwner -->|Role: BusinessOwner| BizDashboard[/business-dashboard]
    LoginAdmin -->|Role: Admin| AdminDashboard[/admin-dashboard]

    %% User Shell Actions
    MainShell -->|Click Business Card| Details[/business-detail/:id]
    MainShell -->|Click AI Feed| AIFeed[/for-you]

    %% Business Owner Actions
    BizDashboard -->|Click Register / Edit| RegisterBiz[/register-business]
    BizDashboard -->|Click Analytics| BizAnalytics[/analytics/:id]
    BizDashboard -->|Click Profile| OwnerProfile[/owner-profile]

    %% Admin Actions
    AdminDashboard -->|Click Heatmap| AdminHeatmap[/admin-heatmap]
```

---

## 2. Router Path Registry (GoRouter)

Below is the complete registry of routes defined in `lib/main.dart`, including path parameters and `extra` arguments:

| Route Path | Screen Component | Route Type | `extra` Parameters / Arguments |
| :--- | :--- | :--- | :--- |
| `/splash` | `SplashScreen` | Public | None |
| `/welcome` | `WelcomeScreen` | Public | None |
| `/login` | `LoginScreen` | Public | `selectedRole` (String?) |
| `/signup` | `SignupScreen` | Public | `preSelectedRole` (String?) |
| `/forgot-password` | `ForgotPasswordScreen`| Public | None |
| `/verify-otp` | `VerifyOtpScreen` | Public | `email` (String) |
| `/reset-password` | `ResetPasswordScreen` | Public | `Map<String, String>` (contains email & otp keys) |
| `/home` | `HomeScreen` | Shell Branch| None |
| `/favorites` | `FavoritesScreen` | Shell Branch| None |
| `/profile` | `ProfileScreen` | Shell Branch| None |
| `/ai-assistant` | `AiAssistantScreen` | Shell Branch| None |
| `/business-dashboard`| `BusinessDashboardScreen`| Protected | None |
| `/admin-dashboard` | `AdminDashboardScreen` | Protected | None |
| `/register-business` | `BusinessRegistrationScreen`| Protected | `BusinessDto`? (Extra payload if editing) |
| `/edit-business/:id` | `BusinessRegistrationScreen`| Protected | `BusinessDto`? (Extra payload to edit) |
| `/owner-profile` | `ProfileScreen` | Protected | None |
| `/business-detail/:id`| `BusinessDetailScreen` | Protected | None (path parameter `id` required) |
| `/analytics/:id` | `AnalyticsDashboardScreen` | Protected | `BusinessDto`? (Extra payload for fast view) |
| `/for-you` | `ForYouFeedScreen` | Protected | None |
| `/admin-heatmap` | `AdminHeatmapScreen` | Protected | None |

---

## 3. Core User Journeys

### A. Authorization & Role Routing Flow
1.  **Splash Start:** Splash screen loads, animating particles. It triggers a background token check in `authProvider`.
2.  **Redirect Controller:**
    *   *If Authenticated:* Checks User Type role. Admins are automatically routed to `/admin-dashboard`, Business Owners/Clients to `/business-dashboard`, and general Users to `/home`.
    *   *If Unauthenticated:* Automatically routed to `/welcome`.

### B. Customer Discovery Flow (User Route)
1.  **Entry:** Arrives on `/home` (within the `MainShell` stack branch).
2.  **Discovery:** Searches via keyword, clicks categories, or selects subcategories. Or triggers `VoiceSearchDialog` to speak a query.
3.  **Detailed Review:** Clicks a business listing to open `/business-detail/:id`.
4.  **Interaction:** Toggles favorite star, calls number, opens website, or enhanced review comment via Llama AI recommendations.

### C. Business Owner Lifecycle Flow (Client Route)
1.  **Hub Landing:** Owner arrives on `/business-dashboard`.
2.  **Add/Edit Store:** Clicks "List your store" to enter `/register-business` (4-step wizard: basic, location map, photos & operating hours, final preview).
3.  **Analytics Tracking:** Clicks "Analytics" on a store card to navigate to `/analytics/:id`, prompting custom AI suggestions based on clicks/views metrics.
4.  **Operational Status Actions:** Can request temporary closure or trigger deletion request (triggers a SignalR live notification request to the admin control panel).

### D. Admin Loop (Admin Route)
1.  **Control Panel:** Landing on `/admin-dashboard` showing counts of Pending/Deletion/Closure requests.
2.  **Task Resolution:** Click Approve/Reject on items to resolve registration states, temporary closure dates, or permanent deletion requests.
3.  **Heatmap Analytics:** Launches `/admin-heatmap` to overlay live approved businesses (gold pins) against user search query densities (red pulsing symbols).
