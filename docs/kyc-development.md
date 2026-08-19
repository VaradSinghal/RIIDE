# KYC Development & Sandbox Guide

When the `KYC_PROVIDER` is set to `mock` (which is the default in local development), the system uses the `MockKycProvider`. This allows developers and QA to test the entire application onboarding flow without requiring actual government documents.

## Deterministic Test Cases

The mock provider responds to specific input values to simulate different verification paths.

### PAN Verification

| PAN Input | Expected Result | Description |
|-----------|----------------|-------------|
| `ABCDE1234F` | **SUCCESS** | Returns a simulated successful NSDL match with 95% name confidence. |
| `XXXXX0000X` | **FAILED** | Simulates an invalid or inactive PAN. |
| *Any other valid format* | **DYNAMIC** | Uses fuzzy-matching between the provided `full_name` and itself to generate a score. If > 85%, passes. |

### Aadhaar / DigiLocker Verification

| Aadhaar Input | OTP Input | Expected Result | Description |
|--------------|-----------|----------------|-------------|
| `999999999999` | `123456` | **SUCCESS** | Simulates a successful Aadhaar authentication via DigiLocker and matches identity. |
| `999999999999` | *Any other* | **FAILED** | Simulates an incorrect OTP entry. |
| *Any other* | `123456` | **FAILED** | Simulates a missing or invalid Aadhaar record. |

## Flutter UI Sandbox Mode
When running the Flutter app, the Registration Screen (Step 2) will prominently display a **"Development / Sandbox Mode"** banner to ensure users know they are not interacting with actual government services.

### Developer Panel
At the bottom of Step 2 (if KYC is not yet verified), a hidden "Developer Panel" provides fast-track buttons:
- **Auto-Fill Success**: Populates the form with `ABCDE1234F` and `999999999999`.
- **Auto-Fill Failed PAN**: Populates the form with `XXXXX0000X`.
- **Fast-Track Verified**: Instantly jumps to the verified state, bypassing API calls entirely (useful for testing Steps 3-5).

## Logs and Security
Even in sandbox mode, the backend enforces security rules. You should verify that full Aadhaar numbers do not appear in normal application logs by checking `gateway/logs` during your tests.
