# Localink End-to-End Project Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [System Architecture](#system-architecture)
3. [Backend Architecture (localink_be)](#backend-architecture-localink_be)
4. [Mobile App Architecture (localink_mobile)](#mobile-app-architecture-localink_mobile)
5. [Database Schema](#database-schema)
6. [API Endpoints](#api-endpoints)
7. [Mobile App Features](#mobile-app-features)
8. [Security & Authentication](#security--authentication)
9. [Advanced Features](#advanced-features)
10. [Deployment & Configuration](#deployment--configuration)

---

## Project Overview

**Localink** is a comprehensive business directory platform designed to connect users with local businesses through a modern, feature-rich ecosystem. The project consists of three main components:

- **localink_be**: .NET 8.0 Web API backend
- **localink_fe**: Angular web frontend (referenced but not analyzed in this document)
- **localink_mobile**: Flutter cross-platform mobile application

### Project Objectives
- Provide seamless business discovery across web and mobile platforms
- Enable business owners to register and manage their business profiles
- Offer intelligent search with AI-powered recommendations
- Facilitate user engagement through reviews, ratings, and favorites
- Deliver real-time analytics and insights for business owners
- Support multi-language accessibility and voice-based interactions

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                         │
│  ┌──────────────────┐          ┌──────────────────┐         │
│  │  Web Frontend    │          │  Mobile App       │         │
│  │  (Angular)       │          │  (Flutter)        │         │
│  └──────────────────┘          └──────────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP/REST API + SignalR
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  Application Layer                           │
│              (localink_be - .NET 8.0 API)                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Controllers │ Services │ Middleware │ Hubs            │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Entity Framework Core
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                               │
│              (SQL Server Database)                           │
│  Users │ Businesses │ Categories │ Reviews │ Messages │ ...  │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack Summary

| Component | Technology | Version |
|-----------|-----------|---------|
| **Backend Framework** | .NET | 8.0 |
| **Backend API** | ASP.NET Core Web API | 8.0 |
| **ORM** | Entity Framework Core | 8.0 |
| **Database** | SQL Server | - |
| **Authentication** | JWT Bearer | - |
| **Real-time** | SignalR | - |
| **Mobile Framework** | Flutter | - |
| **Mobile Language** | Dart | ^3.12.2 |
| **State Management** | Riverpod | ^3.3.2 |
| **Routing** | GoRouter | ^17.3.0 |
| **Networking** | Dio | ^5.10.0 |
| **Maps** | MapLibre GL | ^0.26.2 |

---

## Backend Architecture (localink_be)

### Project Structure

```
localink_be/
├── Controllers/          # API endpoint controllers
├── Data/                 # Database context and models
│   ├── AppDbContext.cs
│   └── Models/
├── Hubs/                 # SignalR real-time hubs
├── Middleware/           # Custom middleware
├── Migrations/           # Database migrations
├── Models/               # Data models
│   ├── DTOs/            # Data transfer objects
│   ├── Entities/        # Database entities
│   └── Enums/           # Enumerations
├── Services/             # Business logic
│   ├── Interfaces/      # Service interfaces
│   └── Implementations/ # Service implementations
├── Program.cs           # Application entry point
└── appsettings.json     # Configuration
```

### Core Dependencies

```xml
- Microsoft.NET.Sdk.Web (8.0)
- Microsoft.EntityFrameworkCore (8.0)
- Microsoft.EntityFrameworkCore.SqlServer (8.0)
- Microsoft.AspNetCore.Authentication.JwtBearer (8.0.7)
- BCrypt.Net-Next (4.1.0) - Password hashing
- MailKit (4.15.1) - Email services
- Swashbuckle.AspNetCore (6.6.2) - Swagger/OpenAPI
- CsvHelper (33.1.0) - CSV processing
- EPPlus (7.0.5) - Excel processing
- Newtonsoft.Json (13.0.4) - JSON serialization
```

### Application Configuration (Program.cs)

The backend follows a modular configuration pattern with:

1. **Environment Variable Mapping**: Maps .env variables to ASP.NET Core configuration
2. **Dependency Injection**: Services registered with scoped lifetimes
3. **Authentication**: JWT Bearer token validation
4. **Rate Limiting**: Global rate limiter (100 requests/minute per IP)
5. **CORS**: Configured for frontend integration
6. **SignalR**: Real-time notification and chat hubs
7. **Static Files**: Configured for file uploads and serving

### Service Layer Architecture

The backend implements a clean service-oriented architecture with:

- **Interface-based design**: All services implement interfaces for testability
- **Scoped lifetime**: Services created per HTTP request
- **Separation of concerns**: Business logic separated from controllers

#### Key Services

| Service | Responsibility |
|---------|---------------|
| `AuthService` | User authentication, registration, password reset |
| `BusinessService` | Business CRUD operations, search, validation |
| `CategoryService` | Category/subcategory management |
| `AdminService` | Admin dashboard, user/business management |
| `AIService` | AI-powered features (reviews, descriptions, chat) |
| `ChatService` | Real-time messaging between users and businesses |
| `FavoritesService` | User favorites management |
| `ReviewService` | Business reviews and ratings |
| `CurrencyService` | Currency conversion via external API |
| `EmailService` | Email notifications (SMTP) |
| `CaptchaService` | CAPTCHA validation |
| `BusinessLocationService` | Geolocation and address validation |

### Middleware Pipeline

1. **ExceptionMiddleware**: Global error handling
2. **ResponseTranslation**: Multi-language response translation
3. **Static Files**: File serving (uploads)
4. **CORS**: Cross-origin resource sharing
5. **Rate Limiter**: Request throttling
6. **Authentication**: JWT validation
7. **Authorization**: Role-based access control

---

## Mobile App Architecture (localink_mobile)

### Project Structure

```
localink_mobile/
├── lib/
│   ├── core/              # Core functionality
│   │   ├── config/       # App configuration
│   │   ├── network/     # HTTP client & SignalR
│   │   ├── storage/     # Secure storage
│   │   └── theme/       # App theming
│   ├── features/         # Feature modules
│   │   ├── admin/       # Admin features
│   │   ├── ai/          # AI assistant
│   │   ├── auth/        # Authentication
│   │   ├── business/    # Business management
│   │   ├── catalog/     # Product catalogs
│   │   ├── chat/        # Real-time messaging
│   │   ├── favorites/   # User favorites
│   │   ├── home/        # Home screen
│   │   ├── profile/     # User profile
│   │   └── shared/      # Shared components
│   └── main.dart        # App entry point
├── android/             # Android-specific code
├── ios/                 # iOS-specific code
└── pubspec.yaml         # Dependencies
```

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.10.0                    # HTTP client
  flutter_riverpod: ^3.3.2       # State management
  go_router: ^17.3.0             # Navigation
  flutter_secure_storage: ^9.2.2  # Secure token storage
  maplibre_gl: ^0.26.2           # Maps
  speech_to_text: ^7.4.0         # Voice recognition
  signalr_netcore: ^1.4.4        # SignalR client
  geolocator: ^14.0.2            # Geolocation
  image_picker: ^1.2.3           # Image capture
  camera: ^0.10.5+9              # Camera access
  fl_chart: ^1.2.0               # Analytics charts
  flutter_tts: ^4.2.5            # Text-to-speech
```

### Architecture Pattern

The mobile app follows a **feature-based architecture** with:

- **Clean Architecture**: Separation of data, domain, and presentation layers
- **Riverpod State Management**: Reactive state management with providers
- **Repository Pattern**: Data access abstraction
- **GoRouter**: Declarative routing with deep linking support

### Core Components

#### Network Layer (`core/network/`)

- **DioClient**: Singleton HTTP client with interceptors
  - Automatic JWT token injection
  - Error handling (401 unauthorized, 429 rate limit)
  - Request/response logging
  - Base URL configuration (supports ngrok for testing)

- **SignalRService**: Real-time connection management
  - Chat notifications
  - Admin notifications
  - Connection state management

#### Storage Layer (`core/storage/`)

- **SecureStorageService**: Flutter Secure Storage wrapper
  - JWT token persistence
  - User data caching
  - Secure credential storage

#### Theme Layer (`core/theme/`)

- **AppTheme**: Material Design 3 theming
  - Custom color palette (saffron orange accent)
  - Typography system (Inter font)
  - Component theming (buttons, cards, inputs)
  - Light/dark theme support

### Feature Modules

#### Authentication Feature (`features/auth/`)

**Data Layer:**
- Models: `AuthResponse`, `LoginRequest`, `RegisterRequest`, `UserProfile`
- Repositories: API calls for login, register, password reset

**Presentation Layer:**
- Screens: Login, Signup, Forgot Password, Verify OTP, Reset Password, Profile
- Providers: `AuthProvider` with state management

**Routes:**
- `/login`, `/signup`, `/forgot-password`, `/verify-otp`, `/reset-password`

#### Business Feature (`features/business/`)

**Data Layer:**
- Models: `BusinessDto`, business-related data structures
- Repositories: Business API integration

**Presentation Layer:**
- Screens: Home, Favorites, Business Dashboard, Registration, Detail, Analytics
- Widgets: Business cards, search components

**Routes:**
- `/home`, `/favorites`, `/business-dashboard`, `/register-business`, `/business-detail/:id`

#### AI Feature (`features/ai/`)

- AI-powered review suggestions
- Business description generation
- Chat-based business search
- Voice transcription

#### Chat Feature (`features/chat/`)

- Real-time messaging between users and businesses
- Voice message support
- Conversation management
- Read receipts

---

## Database Schema

### Entity Relationship Overview

```
Users (1) ──────< (N) Businesses
Users (1) ──────< (N) Favorites
Users (1) ──────< (N) BusinessReviews
Users (1) ──────< (N) Conversations

Businesses (1) ──< (N) BusinessContacts
Businesses (1) ──< (N) BusinessPhotos
Businesses (1) ──< (N) BusinessHours
Businesses (1) ──< (N) BusinessReviews
Businesses (1) ──< (N) Favorites
Businesses (1) ──< (N) Conversations
Businesses (1) ──< (N) Catalogs

Categories (1) ──< (N) Subcategories
Categories (1) ──< (N) Businesses
Subcategories (1) ─< (N) Businesses

Conversations (1) ─< (N) Messages
Catalogs (1) ─────< (N) CatalogItems
```

### Core Entities

#### User
```csharp
public class User {
    public long UserId { get; set; }
    public string AccountType { get; set; }  // "client", "businessowner", "admin"
    public string FullName { get; set; }
    public string Email { get; set; }
    public string? PhoneNumber { get; set; }
    public string CountryCode { get; set; }
    public string? PasswordHash { get; set; }
    public int? OtpAttempts { get; set; }
    public string? PasswordResetOtp { get; set; }
    public DateTime? OtpExpiry { get; set; }
    public string? ProfilePicture { get; set; }
    public ICollection<Business> Businesses { get; set; }
}
```

#### Business
```csharp
public class Business {
    public long BusinessId { get; set; }
    public string BusinessName { get; set; }
    public string Description { get; set; }
    public long UserId { get; set; }
    public int CategoryId { get; set; }
    public int SubcategoryId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public string? TemporaryClosureReason { get; set; }
    public int? TemporaryClosureDays { get; set; }
    public string? TemporaryClosureStatus { get; set; }
    public DateTime? TemporaryClosureReopenDate { get; set; }
}
```

#### BusinessContact
```csharp
public class BusinessContact {
    public long ContactId { get; set; }
    public long BusinessId { get; set; }
    public string PhoneNumber { get; set; }
    public string PhoneCode { get; set; }
    public string Email { get; set; }
    public string Website { get; set; }
    public string StreetAddress { get; set; }
    public string City { get; set; }
    public string State { get; set; }
    public string Country { get; set; }
    public string Pincode { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}
```

#### BusinessReview
```csharp
public class BusinessReview {
    public long ReviewId { get; set; }
    public long BusinessId { get; set; }
    public long UserId { get; set; }
    public int Rating { get; set; }  // 1-5 stars
    public string Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public string? ImageUrl { get; set; }
}
```

#### Conversation & Message
```csharp
public class Conversation {
    public long Id { get; set; }
    public long UserId { get; set; }
    public long BusinessId { get; set; }
    public DateTime LastMessageAt { get; set; }
    public User User { get; set; }
    public Business Business { get; set; }
    public ICollection<Message> Messages { get; set; }
}

public class Message {
    public long Id { get; set; }
    public long ConversationId { get; set; }
    public string SenderRole { get; set; }  // "User" or "Owner"
    public string Content { get; set; }
    public string? VoiceUrl { get; set; }
    public DateTime SentAt { get; set; }
    public bool IsRead { get; set; }
}
```

---

## API Endpoints

### Authentication Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/v1/auth/sessions` | User login | No |
| POST | `/api/v1/auth/register` | User registration | No |
| POST | `/api/v1/auth/forgot-password` | Send password reset OTP | No |
| POST | `/api/v1/auth/reset-password` | Reset password with OTP | No |

### Business Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/business` | Get all businesses | No |
| GET | `/api/v1/business/{id}` | Get business by ID | No |
| POST | `/api/v1/business/register` | Register new business | Yes (Client/BusinessOwner) |
| PUT | `/api/v1/business/{id}` | Update business | Yes (Client/BusinessOwner) |
| DELETE | `/api/v1/business/{id}` | Delete business | Yes (Client/BusinessOwner) |
| GET | `/api/v1/business/my-businesses` | Get user's businesses | Yes |
| GET | `/api/v1/business/search` | Search businesses | No |
| GET | `/api/v1/business/validate-pincode/{pincode}` | Validate pincode | No |
| POST | `/api/v1/business/{id}/temporary-closure` | Request temporary closure | Yes |
| POST | `/api/v1/business/{id}/cancel-temporary-closure` | Cancel temporary closure | Yes |
| POST | `/api/v1/business/{id}/request-deletion` | Request business deletion | Yes |

### Category Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/category` | Get all categories | No |
| GET | `/api/v1/subcategory` | Get all subcategories | No |

### AI Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/v1/ai/review-suggestions` | Get AI review suggestions | No |
| POST | `/api/v1/ai/review-summary` | Get AI review summary | No |
| POST | `/api/v1/ai/generate-description` | Generate business description | No |
| POST | `/api/v1/ai/chat-search` | AI-powered chat search | No |
| POST | `/api/v1/ai/transcribe` | Transcribe audio to text | No |

### Chat Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/chat/user` | Get user conversations | Yes |
| GET | `/api/v1/chat/business/{businessId}` | Get business conversations | Yes |
| GET | `/api/v1/chat/messages/{conversationId}` | Get conversation messages | Yes |
| POST | `/api/v1/chat/read/{conversationId}` | Mark messages as read | Yes |
| POST | `/api/v1/chat/voice/{conversationId}` | Send voice message | Yes |

### Favorites Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/favorites` | Get user favorites | Yes |
| POST | `/api/v1/favorites/{businessId}` | Add to favorites | Yes |
| DELETE | `/api/v1/favorites/{businessId}` | Remove from favorites | Yes |

### Review Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/v1/review` | Submit business review | Yes |
| GET | `/api/v1/review/{businessId}` | Get business reviews | No |

### Admin Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/admin/dashboard` | Get admin dashboard data | Yes (Admin) |
| PUT | `/api/v1/admin/business-status/{id}` | Update business status | Yes (Admin) |
| GET | `/api/v1/admin/export` | Export business data | Yes (Admin) |

### SignalR Hubs

| Hub | Endpoint | Purpose |
|-----|----------|---------|
| `NotificationHub` | `/notifications` | Real-time admin notifications |
| `ChatHub` | `/chat` | Real-time messaging |

---

## Mobile App Features

### User Roles & Workflows

#### 1. Regular User Flow
```
Splash Screen → Welcome → Login/Signup → Home Dashboard
→ Search Businesses → View Details → Add Review → Add to Favorites
```

#### 2. Business Owner Flow
```
Splash Screen → Welcome → Login/Signup → Business Dashboard
→ Register Business → Manage Listings → View Analytics → Chat with Users
```

#### 3. Admin Flow
```
Splash Screen → Welcome → Login → Admin Dashboard
→ Manage Businesses → Review Requests → View Analytics → Heatmap
```

### Core Screens

#### Authentication Screens
- **SplashScreen**: App initialization and auth check
- **WelcomeScreen**: Landing page with login/signup options
- **LoginScreen**: Email/password login with CAPTCHA
- **SignupScreen**: User registration with validation
- **ForgotPasswordScreen**: Password reset initiation
- **VerifyOtpScreen**: OTP verification
- **ResetPasswordScreen**: New password entry
- **ProfileScreen**: User profile management

#### Business Screens
- **HomeScreen**: Main discovery interface with search
- **FavoritesScreen**: User's favorite businesses
- **BusinessDashboardScreen**: Business owner dashboard
- **BusinessRegistrationScreen**: Multi-step business registration
- **BusinessDetailScreen**: Detailed business information
- **AnalyticsDashboardScreen**: Business performance metrics
- **ForYouFeedScreen**: Personalized business recommendations

#### Admin Screens
- **AdminDashboardScreen**: Admin management interface
- **AdminHeatmapScreen**: Geographic business distribution

#### AI & Chat Screens
- **AiAssistantScreen**: AI-powered business assistant
- **ConversationsScreen**: Message list
- **ChatScreen**: Real-time messaging interface

#### Catalog Screens
- **ManageCatalogScreen**: Product catalog management

### Key Features

#### 1. Location-Based Services
- GPS integration for user location
- Pincode validation via Geoapify API
- Distance-based business sorting
- Map integration with MapLibre GL

#### 2. Voice Features
- Voice-to-text search
- Voice message recording and playback
- Text-to-speech for accessibility

#### 3. AI Integration
- AI-powered review suggestions
- Business description generation
- Intelligent chat-based search
- Review summarization

#### 4. Real-Time Features
- SignalR-based notifications
- Real-time chat messaging
- Live status updates

#### 5. Multi-Language Support
- Response translation middleware
- Dynamic language switching
- Localized content delivery

#### 6. Analytics
- Business performance charts (FL Chart)
- User engagement metrics
- Geographic heatmap visualization

---

## Security & Authentication

### JWT Authentication Flow

```
1. User Login → Validate Credentials
2. Generate JWT Token (30-day expiry)
3. Return Token to Client
4. Client Stores Token Securely (Flutter Secure Storage)
5. Subsequent Requests Include Bearer Token
6. Backend Validates Token on Each Request
7. Token Expiry → Redirect to Login
```

### Security Features

#### Backend Security
- **Password Hashing**: BCrypt with salt rounds (12)
- **JWT Validation**: Symmetric key validation with issuer/audience checks
- **Rate Limiting**: 100 requests/minute per IP address
- **CAPTCHA**: Google reCAPTCHA integration
- **Input Validation**: Data annotations with regex patterns
- **SQL Injection Prevention**: Parameterized queries via EF Core
- **CORS**: Configured for specific origins
- **HTTPS**: Enforced in production

#### Mobile Security
- **Secure Storage**: Flutter Secure Storage for tokens
- **Certificate Pinning**: (Configurable for production)
- **Token Refresh**: Automatic token handling
- **Biometric Auth**: (Platform-specific implementation available)

### Role-Based Authorization

| Role | Permissions |
|------|-------------|
| **Admin** | Full system access, business management, user management |
| **BusinessOwner** | Manage own businesses, chat with users, view analytics |
| **Client** | Search businesses, submit reviews, favorites, chat with businesses |

---

## Advanced Features

### 1. AI-Powered Features

#### AI Gateway Service
- Unified AI operations via Groq API
- Review enhancement and suggestions
- Business description generation
- Chat-based business search
- Audio transcription

#### AI Endpoints
- **Review Suggestions**: Enhances user-written reviews
- **Review Summary**: Summarizes multiple reviews
- **Description Generation**: Creates business descriptions from keywords
- **Chat Search**: Natural language business search
- **Audio Transcription**: Voice-to-text conversion

### 2. Real-Time Communication

#### SignalR Implementation
- **NotificationHub**: Admin notifications for business requests
- **ChatHub**: Real-time messaging between users and businesses
- **Group Management**: Users grouped by conversation ID
- **Connection Management**: Automatic reconnection handling

#### Chat Features
- Text messaging
- Voice messages with audio upload
- Read receipts
- Conversation management
- Role-based message routing

### 3. Location Services

#### Geolocation Integration
- **Geoapify API**: Pincode validation and geocoding
- **Country-State-City API**: Hierarchical location data
- **Distance Calculation**: Haversine formula for business proximity
- **Map Integration**: MapLibre GL for visual location display

### 4. Multi-Language Support

#### Translation Middleware
- Response translation based on Accept-Language header
- Translation cache for performance
- Support for multiple languages
- Dynamic content localization

### 5. Analytics & Insights

#### Business Analytics
- View counts and engagement metrics
- Review analysis
- Geographic distribution
- Performance trends
- AI-generated insights

#### Admin Analytics
- Platform-wide statistics
- Business approval workflow
- Geographic heatmap
- User activity tracking

### 6. File Management

#### Upload System
- Image upload for business photos
- Voice message upload
- Static file serving
- Persistent storage configuration
- File validation and security

---

## Deployment & Configuration

### Backend Configuration

#### Environment Variables
```env
DB_CONNECTION_STRING=SQL Server connection string
JWT_SECRET_KEY=JWT signing key (min 16 chars)
JWT_ISSUER=LocalinkAPI
JWT_AUDIENCE=LocalinkUsers
JWT_EXPIRY_MINUTES=43200
JWT_EXPIRY_DAYS=30
CAPTCHA_SECRET_KEY=reCAPTCHA secret key
COUNTRY_CSC_API_KEY=Country-State-City API key
GEOAPIFY_API_KEY=Geoapify API key
GROQ_API_KEY=Groq AI API key
CURRENCY_CONVERTER_API_KEY=Currency API key
ADMIN_EMAIL=admin@localink.com
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USERNAME=email username
EMAIL_PASSWORD=email password
EMAIL_FROM=sender email
UPLOADS_PATH=file upload path
```

#### Database Configuration
- **Provider**: SQL Server
- **Connection**: Integrated Security or SQL Authentication
- **Migrations**: Entity Framework Core migrations
- **Retry Policy**: EnableRetryOnFailure configured

### Mobile Configuration

#### Network Configuration
```dart
// DioClient configuration
static const String backendHost = 'bulldog-kinsman-tutor.ngrok-free.dev';
static const bool useHttps = true;
static const int backendPort = 443;
```

#### Build Configuration
- **Android**: Gradle-based build with keystore signing
- **iOS**: Xcode-based build with provisioning profiles
- **Version**: 1.0.3+4

### Deployment Scripts

#### Backend Deployment
- `deploy_service.sh`: Linux deployment script
- `deploy_to_server.ps1`: PowerShell deployment script
- `publish_be/`: Published output directory

#### Database Migrations
```bash
dotnet ef migrations add MigrationName
dotnet ef database update
```

---

## API Integration Examples

### Mobile to Backend Integration

#### Authentication Flow
```dart
// Login Request
final loginRequest = LoginRequest(
  email: email,
  password: password,
  captchaToken: captchaToken,
);

// API Call
final response = await DioClient().dio.post(
  'auth/sessions',
  data: loginRequest.toJson(),
);

// Token Storage
await SecureStorageService.setToken(response.data['token']);
```

#### Business Search
```dart
// Search with Location
final response = await DioClient().dio.get(
  'business/search',
  queryParameters: {
    'query': searchQuery,
    'sortBy': 'distance',
    'userPincode': userPincode,
  },
  options: Options(
    headers: {
      'X-User-Latitude': userLat,
      'X-User-Longitude': userLng,
      'X-User-City': userCity,
    },
  ),
);
```

#### SignalR Connection
```dart
// Initialize SignalR
final signalRService = SignalRService();
await signalRService.connect();

// Join conversation group
await signalRService.invoke('JoinGroup', args: ['Conv_$conversationId']);

// Listen for messages
signalRService.on('ReceiveMessage', (message) {
  // Handle incoming message
});
```

---

## Testing Strategy

### Backend Testing
- **Framework**: xUnit
- **Mocking**: Moq
- **Assertions**: Fluent Assertions
- **Coverage**: Controllers, Services, Validators

### Mobile Testing
- **Framework**: Flutter Test
- **Widget Testing**: Component testing
- **Integration Testing**: End-to-end flows
- **Mocking**: Mock implementations for services

---

## Performance Optimization

### Backend Optimizations
- **Database Indexing**: Strategic indexes on frequently queried columns
- **Caching**: Memory cache for frequently accessed data
- **Async Operations**: Non-blocking I/O operations
- **Connection Pooling**: Efficient database connection management
- **Response Compression**: Gzip compression for API responses

### Mobile Optimizations
- **Lazy Loading**: On-demand data loading
- **Image Caching**: Network image caching
- **State Management**: Efficient re-renders with Riverpod
- **Pagination**: Paginated API responses
- **Debouncing**: Search input debouncing

---

## Future Enhancements

### Planned Features
- **Push Notifications**: FCM/APNs integration
- **Offline Mode**: Local data caching with sync
- **Advanced Analytics**: ML-based insights
- **Social Features**: Social sharing, referrals
- **Payment Integration**: Business service payments
- **Advanced Search**: Filters, sorting, saved searches
- **Multi-tenant Support**: White-label solutions
- **WebRTC**: Video calling for business consultations

### Technical Improvements
- **Microservices Architecture**: Service decomposition
- **Event Sourcing**: Audit trail and event replay
- **GraphQL**: Alternative to REST API
- **Redis**: Distributed caching
- **CDN Integration**: Static asset delivery
- **Container Orchestration**: Kubernetes deployment

---

## Conclusion

Localink represents a comprehensive, modern full-stack application that successfully integrates:

- **Robust Backend**: .NET 8.0 with clean architecture
- **Cross-Platform Mobile**: Flutter with feature-based architecture
- **Real-Time Features**: SignalR for live updates
- **AI Integration**: Groq-powered intelligent features
- **Modern Security**: JWT authentication with role-based access
- **Scalable Design**: Modular architecture supporting growth

The platform provides a solid foundation for local business discovery and management, with extensibility for future enhancements and scalability for production deployment.

---

**Document Version**: 1.0  
**Last Updated**: July 2026  
**Project**: Localink - Vocal For Sanatan  
**Version**: 1.0.3+4
