# DigiLocker Migration Guide

This document outlines the steps required to transition the GigKavach KYC system from the `MockKycProvider` to the official `DigiLockerKycProvider`.

Because the system was built using a provider-agnostic architecture, **no frontend changes** and **no core database changes** are required to switch providers.

## Migration Checklist

### 1. Procure Credentials
You must register as an official Requester with DigiLocker / API Setu. You will receive:
- `CLIENT_ID`
- `CLIENT_SECRET`

### 2. Configure Environment Variables
In your production `.env` file, update the following configuration block:

```env
# Switch the active provider
KYC_PROVIDER=digilocker

# Provide the official DigiLocker OAuth / API Setu credentials
DIGILOCKER_CLIENT_ID=your_official_client_id
DIGILOCKER_CLIENT_SECRET=your_official_client_secret

# The callback URL registered with DigiLocker
DIGILOCKER_REDIRECT_URI=https://api.gigkavach.com/api/v1/auth/kyc/digilocker/callback

# The base URL (use sandbox for UAT, production for live)
DIGILOCKER_BASE_URL=https://digilocker.gov.in
```

### 3. Implement DigiLocker Provider TODOs
The `DigiLockerKycProvider` class (`services/gateway/app/kyc/digilocker_provider.py`) contains the integration boundary. Before migrating to production, a backend engineer must implement the actual network calls in this file.

- **`verify_pan()`**: Implement the API Setu call to fetch Income Tax Department records. (Reference: *API Setu PAN Verification API*)
- **`send_aadhaar_otp()`**: Implement the UIDAI OTP trigger via the DigiLocker gateway.
- **`verify_identity()`**: 
  - Complete the OAuth Token exchange.
  - Fetch the user's `Aadhaar` document XML from the DigiLocker repository.
  - Parse the XML to extract the name, DOB, and masked Aadhaar.
  - Run the `difflib` name match comparison against the PAN name.
  - Return the structured `VerificationResult`.

### 4. Remove Development Overrides
Ensure that `APP_ENV=production` is set. 
Remove `ALLOW_MOCK_IN_PROD=true` if it was temporarily added during staging. The gateway will now enforce that `KYC_PROVIDER=digilocker` is active and will fail safely if credentials are missing.

### 5. Update Flutter UI (Optional)
Once successfully verified, the Flutter `RegistrationScreen` will automatically read `provider: "digilocker"` from the `KycCompleteResponse` and update the UI to state: 
`Verification Provider: DigiLocker`.
The Sandbox banner will no longer appear if the backend state reflects a production provider.
