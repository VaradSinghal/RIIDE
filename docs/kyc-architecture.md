# KYC Architecture

The GigKavach KYC system is designed to be **provider-agnostic**, ensuring smooth transitions between simulated development environments and official production identity verification services (like DigiLocker).

## The Provider Abstraction
At the core of the system is the `KycProvider` interface (`services/gateway/app/kyc/provider.py`). It defines the following contract:
- `initiate_kyc(user_id)`
- `get_kyc_status(session_id)`
- `verify_pan(pan, dob, name)`
- `init_digilocker(session_id)`
- `send_aadhaar_otp(session_id, aadhaar_number)`
- `verify_identity(session_id, aadhaar_number, otp)`

### Available Providers
1. **`MockKycProvider`**: Used for development and testing. Simulates network calls and uses deterministic values to test success/failure flows without requiring real identities.
2. **`DigiLockerKycProvider`**: Used for production. Integrates directly with the official DigiLocker OAuth / API Setu systems to securely fetch and verify authentic government documents.

## Configuration & Environment Safety
The active provider is determined by the `KYC_PROVIDER` environment variable loaded by the `get_kyc_provider()` factory.

**Safety Mechanism**: 
If `APP_ENV=production` and `KYC_PROVIDER=mock`, the gateway will **fail to start** unless explicitly overridden by `ALLOW_MOCK_IN_PROD=true`. This prevents the application from accidentally approving real users using fake data in a production environment.

## Data Model & State Machine
The database model `KycRecord` tracks the complete state of a user's identity verification session. 

**Possible States (`kyc_status`)**:
- `NOT_STARTED`
- `PENDING`
- `CONSENT_REQUIRED`
- `IDENTITY_VERIFICATION`
- `DOCUMENT_RETRIEVAL`
- `VERIFIED`
- `FAILED`
- `EXPIRED`
- `CANCELLED`

All records are explicitly tagged with the `provider` and `environment` used to verify them (e.g., `mock` / `development`). The system preserves the distinction that a mock verification is *not* a government verification.

## API Contract
The frontend communicates entirely with our gateway API, not with the providers directly.

1. `POST /api/v1/auth/kyc/start` -> returns sessionId
2. `GET /api/v1/auth/kyc/:sessionId`
3. `POST /api/v1/auth/kyc/:sessionId/identity` (PAN Match)
4. `POST /api/v1/auth/kyc/:sessionId/consent` (DigiLocker Init)
5. `POST /api/v1/auth/kyc/:sessionId/aadhaar` (Aadhaar OTP trigger)
6. `POST /api/v1/auth/kyc/:sessionId/complete` (Finalize liveness & OTP)
