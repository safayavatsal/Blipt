# Blipt — Vehicle Intelligence, Instantly.

Point at a plate, get everything about the vehicle, instantly.

Blipt is a camera-first iOS app that scans Indian license plates using on-device OCR and returns vehicle location, registration details, insurance status, challan history, and more.

## Features

**Free (Offline)**
- Live camera plate scanning with real-time detection
- Photo upload scanning
- Plate → State + District + RTO identification
- 1,210 RTOs across 36 Indian states/UTs
- Morocco support (87 cities)
- Browse all states and RTOs with search

**Premium**
- Full vehicle details (make, model, fuel, class)
- Insurance status with active/expired badges
- Challan history with amounts and payment status
- Fitness certificate validity tracking

## Tech Stack

### iOS App
- **SwiftUI** — iOS 17+, Swift 6 strict concurrency
- **Apple Vision** — `VNRecognizeTextRequest` for on-device OCR (zero third-party deps)
- **AVFoundation** — Live camera with 5 FPS plate detection
- **MapKit** — Location pins for RTO offices
- **StoreKit 2** — Subscription management
- **Observation** — `@Observable` framework throughout

### Backend
- **FastAPI** — Python async backend
- **Surepass API** — Vehicle data proxy with PII stripping
- **Railway** — Deployment with Dockerfile

### Architecture
- Protocol-based services (OCR, parsing, data, network)
- Country-agnostic design (India + Morocco, extensible)
- Hybrid plate parser (regex + fuzzy matching for OCR errors)
- Actor-based API client with retry and backoff

## Project Structure

```
Blipt/
├── App/                    # AppState, Constants, Theme, DI
├── Models/                 # Domain models + API responses
├── Services/
│   ├── Analytics/          # Privacy-first event tracking
│   ├── Camera/             # CameraManager, PlateDetector
│   ├── Data/               # RTODataService, MoroccoDataService
│   ├── Network/            # APIClient, VahanAPI, Connectivity
│   ├── OCR/                # VisionOCRService, MockOCR
│   ├── PlateParser/        # Indian + Moroccan parsers, FuzzyMatcher
│   └── Subscription/       # StoreKit 2, PaywallManager
├── ViewModels/             # Scan, Browse, Result, Vehicle, Subscription
├── Views/
│   ├── Scan/               # Camera-first UI, overlays, result sheet
│   ├── Result/             # Plate result, vehicle details, insurance, challans
│   ├── Browse/             # State/RTO browser with search
│   ├── Paywall/            # Subscription UI
│   ├── Settings/           # Country picker, data submission
│   └── Components/         # Logo, plate visualizer, map, shimmer, errors
└── Resources/Data/         # indian_rto_data.json, moroccan_cities.json

Backend/
├── main.py                 # FastAPI app
├── routers/                # health, vahan, countries, submissions
├── services/               # Surepass client with caching
├── middleware/              # Rate limiting, auth
├── models/                 # Pydantic models
└── Dockerfile + railway.toml

Tests/                      # 66 unit tests (0 failures)
```

## Indian Plate Format

**Standard:** `[SS] [DD] [XX] [NNNN]` — e.g., MH 12 AB 1234 (Maharashtra, Pune)

**BH Series:** `[YY] BH [NNNN] [X]` — e.g., 24 BH 5678 C (National permit)

The parser handles spaces, dashes, OCR errors (O↔0, I↔1, B↔8, S↔5), and validates against all 36 state codes.

## Getting Started

### iOS App
1. Clone the repo
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
3. Generate the Xcode project: `xcodegen generate`
4. Open `Blipt.xcodeproj` in Xcode
5. Select your target device and press Cmd+R

### Backend
1. `cd Backend`
2. `pip install -r requirements.txt`
3. Create `.env` with `SUREPASS_API_KEY=your_key`
4. `uvicorn Backend.main:app --reload`

### Tests
```bash
xcodebuild -project Blipt.xcodeproj -scheme BliptTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## License

Distributed under the MIT license. See `LICENSE` for more information.
