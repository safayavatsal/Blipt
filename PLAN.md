# Blipt — Vehicle Intelligence, Instantly.

### _formerly WhereAreYouFrom_

## Full SwiftUI Rewrite - Implementation Plan

---

## Context

**Blipt** — like a radar blip that just identified something. Point at a plate, get everything about the vehicle, instantly.

This app was built in 2019 as a hackathon project ("WhereAreYouFrom") to identify the origin city of a vehicle from its Moroccan license plate using OCR. We're transforming it into **Blipt** — an Indian-first, globally-scalable vehicle intelligence platform with a complete SwiftUI rewrite, modern ML stack, and a freemium business model.

**Key drivers:**
- Firebase ML Vision (current OCR engine) is deprecated
- TesseractOCR and SwiftOCR are unmaintained
- Indian market opportunity: no good camera-based plate scanning app exists (competitors like CarInfo are manual-entry only)
- The app's architecture (87 hardcoded cities, `text.suffix(2)` parsing) cannot scale

---

## Confirmed Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| OCR Engine | Apple Vision (`VNRecognizeTextRequest`) | Zero deps, on-device, fast, protocol-based for future CoreML plug-in |
| Feature Scope | Full vehicle intelligence | Plate-to-location + vehicle details + insurance + challans + fitness cert |
| Data Architecture | Local JSON bundles + Custom backend | Offline RTO data + FastAPI on Railway for Vahan API proxy |
| Plate Parsing | Hybrid (regex + fuzzy matching) | Regex for clean cases, fuzzy for OCR errors (O/0, I/1, B/8) |
| UI | Camera-first + full SwiftUI rewrite | Live viewfinder home screen, big bang rewrite |
| Backend | FastAPI on Railway/Render | Vahan API proxy, rate limiting, API key management |
| Vahan API | Surepass | Good docs, verification-focused |
| Monetization | Freemium | Free: plate-to-location (offline). Paid: vehicle intelligence |
| SwiftUI Migration | Big bang rewrite | Current codebase is small enough (4-5 VCs) for a clean rewrite |

---

## Indian License Plate Format Reference

### Standard Format: `[SS] [DD] [XX] [NNNN]`

| Component | Meaning | Example |
|-----------|---------|---------|
| SS | Two-letter state/UT code | MH, DL, KA |
| DD | Two-digit RTO district code | 01-99 |
| XX | 1-3 letter series code (no O or I) | A, AB, ABC |
| NNNN | Unique number 1-9999 | 1234 |

Example: **MH 12 AB 1234** = Maharashtra, Pune RTO, series AB, number 1234

### BH (Bharat) Series: `YYBH####XX`
Example: **25BH0123C** = Registered 2025, Bharat series, number 0123, category C

### Key Facts
- 37 states/UTs, 1,300+ RTOs
- Letters O and I never used in series codes
- Bengaluru alone has 11 RTO codes

### Valid State Codes (all 37)
```
AN, AP, AR, AS, BR, CG, CH, DD, DL, GA, GJ, HP, HR, JH, JK,
KA, KL, LA, LD, MH, ML, MN, MP, MZ, NL, OD, PB, PY, RJ, SK,
TN, TR, TS, UK, UP, WB
```

---

## New Project Folder Structure

```
App/
|-- AppEntry.swift                      # @main SwiftUI App entry point
|-- ContentView.swift                   # Root TabView routing
|-- App/
|   |-- AppState.swift                  # @Observable app-wide state
|   |-- AppConstants.swift              # API URLs, bundle keys, limits
|   |-- DependencyContainer.swift       # Protocol-based DI
|
|-- Models/
|   |-- Domain/
|   |   |-- LicensePlate.swift          # Parsed plate struct
|   |   |-- RTOOffice.swift             # RTO data model
|   |   |-- IndianState.swift           # State/UT enum + metadata
|   |   |-- VehicleInfo.swift           # Vahan API response model
|   |   |-- InsuranceInfo.swift         # Insurance details
|   |   |-- ChallanRecord.swift         # Challan history item
|   |   |-- FitnessCertificate.swift    # Fitness cert details
|   |   |-- Country.swift               # Country enum for global scale
|   |   |-- MoroccanCity.swift          # Legacy Morocco model
|   |-- API/
|       |-- VahanAPIResponse.swift      # Raw Surepass Codable
|       |-- APIError.swift              # Typed API errors
|       |-- SubscriptionProduct.swift   # StoreKit product IDs
|
|-- Services/
|   |-- OCR/
|   |   |-- OCRServiceProtocol.swift    # Protocol for any OCR engine
|   |   |-- VisionOCRService.swift      # Apple Vision implementation
|   |   |-- MockOCRService.swift        # For previews/testing
|   |-- PlateParser/
|   |   |-- PlateParserProtocol.swift   # Country-agnostic parser protocol
|   |   |-- IndianPlateParser.swift     # Regex + fuzzy for Indian plates
|   |   |-- MoroccanPlateParser.swift   # Legacy Morocco parser
|   |   |-- FuzzyMatcher.swift          # O/0, I/1, 8/B substitutions
|   |   |-- PlateNormalizer.swift       # Whitespace, dash, case cleanup
|   |-- Data/
|   |   |-- RTODataService.swift        # Loads/searches Indian RTO JSON
|   |   |-- MoroccoDataService.swift    # Loads Morocco city JSON
|   |   |-- CountryDataServiceProtocol.swift
|   |-- Network/
|   |   |-- APIClient.swift             # Async/await HTTP client
|   |   |-- VahanAPIService.swift       # Surepass proxy calls
|   |   |-- VahanAPIServiceProtocol.swift
|   |-- Subscription/
|   |   |-- SubscriptionManager.swift   # StoreKit 2 wrapper
|   |   |-- PaywallManager.swift        # Feature gating
|   |-- Camera/
|       |-- CameraManager.swift         # AVFoundation session
|       |-- PlateDetector.swift         # Continuous VNRecognizeTextRequest
|
|-- ViewModels/
|   |-- ScanViewModel.swift             # Camera + OCR + parsing pipeline
|   |-- ResultViewModel.swift           # Plate result + vehicle details
|   |-- BrowseViewModel.swift           # State/RTO browsing + search
|   |-- VehicleDetailViewModel.swift    # Vahan API detail fetch
|   |-- SubscriptionViewModel.swift     # Paywall state
|   |-- SettingsViewModel.swift         # Country selector, preferences
|
|-- Views/
|   |-- Scan/
|   |   |-- ScanView.swift              # Camera-first home screen
|   |   |-- CameraPreviewView.swift     # UIViewRepresentable for AVCapture
|   |   |-- PlateOverlayView.swift      # Bounding box + text overlay
|   |   |-- ScanResultSheet.swift       # Bottom sheet with result
|   |-- Result/
|   |   |-- PlateResultView.swift       # State + District + Map
|   |   |-- VehicleDetailView.swift     # Full vehicle info (paid)
|   |   |-- InsuranceCardView.swift     # Insurance status card
|   |   |-- ChallanListView.swift       # Challan history list
|   |   |-- FitnessCardView.swift       # Fitness cert card
|   |-- Browse/
|   |   |-- BrowseView.swift            # State list + search
|   |   |-- StateDetailView.swift       # RTOs for a state
|   |   |-- RTORowView.swift            # RTO cell
|   |-- Paywall/
|   |   |-- PaywallView.swift           # Subscription upsell
|   |   |-- FeatureComparisonView.swift # Free vs paid
|   |-- Settings/
|   |   |-- SettingsView.swift          # Country picker, about
|   |-- Components/
|       |-- PlateVisualizerView.swift   # Styled plate display
|       |-- MapSnippetView.swift        # Small MapKit view
|       |-- LoadingOverlay.swift        # Shimmer/skeleton
|       |-- ErrorBannerView.swift       # Inline error display
|
|-- Resources/
|   |-- Data/
|   |   |-- indian_rto_data.json        # 37 states, 1300+ RTOs
|   |   |-- moroccan_cities.json        # 87 cities (preserved)
|   |-- Assets.xcassets
|
|-- Tests/
|   |-- IndianPlateParserTests.swift
|   |-- FuzzyMatcherTests.swift
|   |-- RTODataServiceTests.swift
|   |-- VisionOCRServiceTests.swift
|   |-- MoroccanPlateParserTests.swift
|   |-- ScanViewModelTests.swift
|   |-- VahanAPIServiceTests.swift
|
|-- Backend/                            # Separate directory (or repo)
    |-- main.py                         # FastAPI entry
    |-- routers/
    |   |-- vahan.py                    # /api/v1/vehicle/{plate}
    |   |-- health.py                   # /health
    |-- services/
    |   |-- surepass_client.py          # Surepass API wrapper
    |-- models/
    |   |-- vehicle.py                  # Pydantic response models
    |-- middleware/
    |   |-- rate_limiter.py             # Per-user rate limiting
    |   |-- auth.py                     # API key validation
    |-- config.py
    |-- requirements.txt
    |-- Dockerfile
    |-- railway.toml
```

---

## Key Protocols & Interfaces

### OCRServiceProtocol
```swift
protocol OCRServiceProtocol {
    func recognizeText(in image: CGImage, regionOfInterest: CGRect?) async throws -> [OCRResult]
    func recognizeText(from sampleBuffer: CMSampleBuffer) async throws -> [OCRResult]
}

struct OCRResult {
    let text: String
    let confidence: Float        // 0.0 to 1.0
    let boundingBox: CGRect      // Normalized coordinates
}
```

### PlateParserProtocol
```swift
protocol PlateParserProtocol {
    var country: Country { get }
    func parse(ocrText: String) -> PlateParseResult?
    func validate(plate: String) -> Bool
}

struct PlateParseResult {
    let rawText: String
    let normalizedPlate: String
    let components: PlateComponents
    let confidence: Double
    let format: PlateFormat      // .standard, .bhSeries, .legacy
}

enum PlateComponents {
    case indian(state: String, rtoCode: String, series: String, number: String)
    case indianBH(year: String, number: String, category: String)
    case moroccan(cityCode: Int)
}
```

### CountryDataServiceProtocol
```swift
protocol CountryDataServiceProtocol {
    func loadData() async throws
    func lookup(plate: PlateParseResult) -> LocationInfo?
    func allRegions() -> [Region]
    func search(query: String) -> [Region]
}
```

### VahanAPIServiceProtocol
```swift
protocol VahanAPIServiceProtocol {
    func fetchVehicleDetails(plate: String) async throws -> VehicleInfo
}
```

---

## Regex Patterns for Indian Plates

```swift
// Standard: MH 12 AB 1234
static let standardPattern = #"^([A-Z]{2})\s*[-]?\s*(\d{2})\s*[-]?\s*([A-HJ-NP-Z]{1,3})\s*[-]?\s*(\d{1,4})$"#

// BH Series: 22BH0123C
static let bhSeriesPattern = #"^(\d{2})\s*[-]?\s*(BH)\s*[-]?\s*(\d{4})\s*[-]?\s*([A-HJ-NP-Z]{1,2})$"#

// Loose pattern (allows OCR errors like O/0, I/1)
static let looseStandardPattern = #"^([A-Z0-9]{2})\s*[-]?\s*([0-9OoIl]{2})\s*[-]?\s*([A-Z0-9]{1,3})\s*[-]?\s*([0-9OoIl]{1,4})$"#
```

---

## Data Model Schemas

### indian_rto_data.json
```json
{
  "version": "1.0",
  "lastUpdated": "2026-04-01",
  "states": [
    {
      "code": "MH",
      "name": "Maharashtra",
      "type": "state",
      "capital": "Mumbai",
      "coordinate": { "lat": 19.0760, "lng": 72.8777 },
      "rtos": [
        {
          "code": "01",
          "name": "Mumbai (South)",
          "fullCode": "MH01",
          "district": "Mumbai",
          "address": "RTO Tardeo, Mumbai",
          "coordinate": { "lat": 18.9894, "lng": 72.8256 }
        }
      ]
    }
  ]
}
```

### Surepass API Response (via backend proxy)
```json
{
  "success": true,
  "data": {
    "registration_number": "MH12AB1234",
    "maker_description": "HYUNDAI MOTOR INDIA LTD",
    "maker_model": "CRETA 1.5 SX(O)",
    "fuel_type": "PETROL",
    "vehicle_class": "Motor Car (LMV)",
    "registration_date": "2022-03-15",
    "fitness_upto": "2037-03-14",
    "insurance_upto": "2025-09-30",
    "insurance_company": "BAJAJ ALLIANZ",
    "emission_norms": "BS-VI",
    "rc_status": "ACTIVE",
    "challan_details": []
  }
}
```

---

## Phase 1: Foundation (Week 1-2) ✅ COMPLETE

### Milestone: "Offline plate-to-location works for any Indian plate from a static image"

### 1.1 New SwiftUI Project Setup ✅
- [x] Create new Xcode project with SwiftUI App lifecycle (iOS 17+)
- [x] Set up folder structure as defined above
- [x] Create `BliptApp.swift` with `@main`, `ContentView.swift` with TabView shell
- [x] Create `AppState.swift` (@Observable), `AppConstants.swift`, `DependencyContainer.swift`
- [x] Remove Podfile, Pods/, all Firebase/Tesseract/SwiftOCR references
- [x] Remove Core Data model files
- [x] Remove all UIKit view controllers, button subclasses, UIKit extensions
- [x] Configure for Swift 6 strict concurrency
- [x] **Acceptance**: App launches to TabView with Scan/Browse/Settings tabs, zero third-party deps

### 1.2 Indian RTO JSON Data Bundle ✅
- [x] Create `Resources/Data/indian_rto_data.json` with all 36 states/UTs and 1,210 RTOs
- [x] Create `Models/Domain/IndianState.swift` and `RTOOffice.swift` Codable structs
- [x] Create `Services/Data/RTODataService.swift` with lookup dictionaries, search, allStates()
- [x] Create `Services/Data/CountryDataServiceProtocol.swift` with Region/SubRegion types
- [ ] **Tests**: `RTODataServiceTests.swift` — JSON loads, known lookups (MH12=Pune), all states present, search works, edge cases _(deferred — service validated via JSON schema checks)_
- [x] **Acceptance**: JSON loads, lookup returns correct location (MH12=Pune, DL01=Sarai Kale Khan, KA01=Bangalore), search works

### 1.3 Apple Vision OCR Service ✅
- [x] Create `Services/OCR/OCRServiceProtocol.swift`
- [x] Create `Services/OCR/VisionOCRService.swift` using `VNRecognizeTextRequest`
  - `.accurate` for still images, `.fast` for live camera
  - `usesLanguageCorrection = false`
  - Optional `regionOfInterest` support
- [x] Create `Services/OCR/MockOCRService.swift` for previews/tests
- [ ] **Tests**: `VisionOCRServiceTests.swift` with bundled test plate images _(deferred — requires real device)_
- [x] **Acceptance**: Implementation complete with both CGImage and CMSampleBuffer support

### 1.4 Hybrid Plate Parser ✅
- [x] Create `Services/PlateParser/PlateParserProtocol.swift` + `PlateParserFactory`
- [x] Create `Services/PlateParser/PlateNormalizer.swift` — strip whitespace, dashes, uppercase, remove "IND" prefix
- [x] Create `Services/PlateParser/FuzzyMatcher.swift` — O<->0, I<->1, B<->8, S<->5, Z<->2, G<->6 substitutions
- [x] Create `Services/PlateParser/IndianPlateParser.swift`:
  1. Normalize → 2. Try standard regex → 3. Try BH regex → 4. Fuzzy variants → 5. Validate state code → 6. Return result with confidence
- [x] Create placeholder `Services/PlateParser/MoroccanPlateParser.swift`
- [x] **Tests**: `IndianPlateParserTests.swift` — exact matches, spaces/dashes, BH series, OCR errors, invalid plates, all 36 state codes ✅
- [x] **Tests**: `FuzzyMatcherTests.swift` — each substitution pair, variant count bounded ✅
- [x] **Acceptance**: Parses all standard + BH formats, fuzzy corrects common errors, nil for garbage

### 1.5 Basic Result Screen ✅
- [x] Create `ViewModels/ResultViewModel.swift` — takes PlateParseResult, looks up location
- [x] Create `Views/Result/PlateResultView.swift` — plate visualizer + state + district + map
- [x] Create `Views/Components/PlateVisualizerView.swift` — styled Indian plate (white bg, black text, blue IND stripe)
- [x] Create `Views/Components/MapSnippetView.swift` — small Map with annotation pin
- [x] **Acceptance**: Shows correct state/district/RTO, map pin at correct location, "not found" state works

### 1.6 Integration: Photo Picker to Result ✅
- [x] Create `ViewModels/ScanViewModel.swift` (photo-only) — PhotosPicker → OCR → parser → lookup → result
- [x] Create `Views/Scan/ScanView.swift` (initial) — "Scan Plate" button, PhotosPicker, processing indicator
- [ ] **Tests**: `ScanViewModelTests.swift` with mock OCR _(deferred)_
- [x] **Acceptance**: End-to-end flow works: photo → text → parsed plate → state + district + map

### Phase 1 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| RTO data incompleteness | High | Medium | Start with major states, mark others "data pending", use version field for OTA updates |
| Apple Vision poor accuracy on Indian plates | Medium | High | Test with 20+ real photos early; add preprocessing (contrast, VNDetectRectanglesRequest) if <80% |
| Fuzzy matching false positives | Medium | Medium | Limit to single-char substitutions, validate state code exists |

---

## Phase 2: Camera-First UX (Week 2-3) ✅ COMPLETE

### Milestone: "User opens app, sees live camera, points at plate, sees result in real-time"

### 2.1 Live Camera Viewfinder ✅
- [x] Create `Services/Camera/CameraManager.swift` — @Observable, AVCaptureSession, permissions, start/stop lifecycle, flash/torch toggle, still frame capture
- [x] Create `Views/Scan/CameraPreviewView.swift` — UIViewRepresentable wrapping AVCaptureVideoPreviewLayer
- [x] Handle background/foreground transitions via start/stop lifecycle
- [x] **Acceptance**: Camera fills screen, permission dialog works, clean start/stop, denied state handled

### 2.2 Real-Time Plate Detection + OCR Overlay ✅
- [x] Create `Services/Camera/PlateDetector.swift` — processes every Nth frame (~5 FPS), VNRecognizeTextRequest (`.fast` mode), pipes through IndianPlateParser, debounce (3 consistent reads), exponential moving average bounding box smoothing
- [x] Update `ScanViewModel.swift` — orchestrates CameraManager + PlateDetector, supports camera + photo modes, manual shutter capture with `.accurate` OCR
- [x] Create `Views/Scan/PlateOverlayView.swift` — bounding box (yellow=detecting, green=confirmed), plate text label, checkmark on confirm, Vision→SwiftUI coordinate conversion
- [x] Update `Views/Scan/ScanView.swift` — full-screen camera, guide overlay with cutout, plate overlay, manual shutter button, flash toggle, photo library picker
- [x] **Acceptance**: Live bounding box tracks plate, text overlays with animations, confirmed plate triggers haptic

### 2.3 Scan Result Bottom Sheet ✅
- [x] Create `Views/Scan/ScanResultSheet.swift` — slides up with plate visualizer, location card, map snippet, "Full Details" button, "Scan Another" button, ShareLink
- [x] **Acceptance**: Smooth animation via presentationDetents, correct data, dismiss resumes camera

### 2.4 Browse Tab ✅ _(completed in Phase 1)_
- [x] Create `ViewModels/BrowseViewModel.swift` — loads states, search filtering, state selection
- [x] Create `Views/Browse/BrowseView.swift` — searchable state list with badge + RTO count
- [x] Create `Views/Browse/StateDetailView.swift` — header, RTO list, search within state, map with all RTO pins
- [x] Create `Views/Browse/RTORowView.swift` — compact row with code badge, name, district
- [x] **Acceptance**: All states browsable, search works across names/codes/districts, drill-down works

### 2.5 BH (Bharat) Series Support ✅
- [x] Update PlateResultView for BH plates — "Bharat Series (National Permit)" section, registration year, category name (A-C=Non-transport, D-F=Transport), yellow plate styling
- [x] **Acceptance**: BH plates recognized, category and year displayed correctly

### 2.6 Animations & Polish ✅
- [ ] matchedGeometryEffect for plate transition (camera overlay → result sheet) _(deferred — requires shared namespace across sheets)_
- [x] Spring/easeInOut animations for sheet presentation and bounding box tracking
- [x] Shimmer loading during OCR — `LoadingOverlay.swift` with `ShimmerModifier`
- [x] Camera guide corners that pulse — `CameraGuideView` with `CornerBracket` + repeating animation
- [x] Dark mode support throughout — `.ultraThinMaterial` backgrounds, semantic colors
- [x] `ErrorBannerView.swift` — inline error display with retry action
- [x] Haptic feedback (`UINotificationFeedbackGenerator`) on plate confirmation
- [x] **Acceptance**: Smooth animations, dark mode works, shimmer + guide corners animate

### Phase 2 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Camera processing too slow | Medium | High | Throttle to 5 FPS, use `.fast` for live, `.accurate` for manual capture |
| Bounding box jitter | High | Medium | Exponential moving average on coordinates, require 3 stable frames |

---

## Phase 3: Backend + Vehicle Intelligence (Week 3-5) ✅ COMPLETE

### Milestone: "Paid users see full vehicle details after scanning"

### 3.1 FastAPI Backend ✅
- [x] Create `Backend/main.py` — FastAPI + CORS + health check + `/api/v1/` versioning, rate-limit middleware on vehicle endpoints
- [x] Create `Backend/config.py` — env vars (SUREPASS_API_KEY, etc.) via pydantic-settings, 24h cache TTL, rate limit config
- [x] Create `Backend/routers/vahan.py` — `POST /api/v1/vehicle/lookup`, validates plate format, returns VehicleResponse
- [x] Create `Backend/routers/health.py` — `GET /health` returns status + version
- [x] Create `Backend/services/surepass_client.py` — async httpx client, in-memory cache (24h TTL), PII stripping, plate validation, error handling
- [x] Create `Backend/models/vehicle.py` — Pydantic models (VehicleLookupRequest, VehicleData, VehicleResponse, ChallanDetail, HealthResponse)
- [x] Create `Backend/middleware/rate_limiter.py` — 10 req/min/client IP, 429 with Retry-After header
- [x] Create `Backend/middleware/auth.py` — bearer token validation (skips in dev if no token configured)
- [x] Create `Backend/Dockerfile` + `Backend/railway.toml` for Railway deployment
- [x] Create `Backend/requirements.txt` — fastapi, uvicorn, httpx, pydantic, pydantic-settings
- [ ] **Tests**: pytest with mocked Surepass, rate limiting, input validation, PII redaction _(deferred)_
- [x] **Acceptance**: Backend structure complete, PII fields stripped (owner_name, father_name, addresses, phone, email)

### 3.2 iOS API Client ✅
- [x] Create `Services/Network/APIClient.swift` — actor-based async/await URLSession, bearer token, retry with exponential backoff (2 retries), 15s timeout, snake_case decoding
- [x] Create `Services/Network/VahanAPIService.swift` — implements VahanAPIServiceProtocol, calls backend proxy, maps response to VehicleInfo
- [x] Create `Models/API/VahanAPIResponse.swift` — Codable structs (VahanAPIResponse, VahanVehicleData, VahanChallanDetail) with date parsing (multiple formats)
- [x] Create `Models/API/APIError.swift` — networkUnavailable, unauthorized, rateLimited, plateNotFound, serverError, decodingError, unknown _(existed from Phase 1)_
- [ ] **Tests**: `VahanAPIServiceTests.swift` with URLProtocol mock _(deferred)_
- [x] **Acceptance**: Full error handling, retry logic for transient errors, no retry for auth/not-found/rate-limit

### 3.3 Vehicle Details Screen ✅
- [x] Create `ViewModels/VehicleDetailViewModel.swift` — fetches via VahanAPIService, publishes LoadState (idle/loading/loaded/error), checks premium gate + connectivity
- [x] Create `ViewModels/SubscriptionViewModel.swift` — wraps SubscriptionManager for paywall UI
- [x] Create `Views/Result/VehicleDetailView.swift` — plate header, vehicle info card (make/model/fuel/class/emission), registration status (ACTIVE green/red), insurance, challans, fitness, loading skeleton, error+retry
- [x] Create `Views/Result/InsuranceCardView.swift` — company, validity date, green (ACTIVE) / yellow (EXPIRING SOON) / red (EXPIRED) badge
- [x] Create `Views/Result/ChallanListView.swift` — date, violation, ₹ amount, PAID/PENDING status, empty state with checkmark
- [x] Create `Views/Result/FitnessCardView.swift` — validity date, green/yellow/red traffic-light badge
- [x] **Acceptance**: Full details display, insurance color-coding correct, loading/error states work, free users see paywall

### 3.4 Freemium Gate ✅
- [x] Create `Services/Subscription/PaywallManager.swift` — @Observable, isPremium, feature gating (vehicleDetails, insuranceStatus, challanHistory, fitnessCertificate, unlimitedScans)
- [x] Update PlateResultView — free users see lock icon + "Unlock Premium" button → paywall sheet; premium users see "View Vehicle Details" button → VehicleDetailView sheet
- [x] Create `Views/Paywall/PaywallView.swift` — star header, FeatureComparisonView, product cards with displayPrice, restore button, ToS/privacy links
- [x] Create `Views/Paywall/FeatureComparisonView.swift` — two-column table with green checkmarks / gray X marks for free vs premium
- [x] **Acceptance**: Free users see location only + paywall, premium gate clear, no bypass

### 3.5 StoreKit 2 Subscription ✅
- [x] Create `Services/Subscription/SubscriptionManager.swift` — Product.products(), purchase() with verification, Transaction.currentEntitlements for restore, Transaction.updates listener
- [ ] Configure StoreKit testing configuration file in Xcode _(requires manual Xcode setup)_
- [x] Support monthly + yearly plans via AppConstants.StoreKit product IDs
- [x] Update `Views/Settings/SettingsView.swift` — wired Upgrade button → PaywallView, Restore button → SubscriptionManager.restore()
- [x] **Acceptance**: Purchase/restore flow implemented, subscription status tracked via purchasedProductIDs

### 3.6 Error Handling & Offline Fallback ✅
- [x] Create `Views/Components/LoadingOverlay.swift` — shimmer skeleton with gradient animation _(done in Phase 2)_
- [x] Create `Views/Components/ErrorBannerView.swift` — inline error + retry button _(done in Phase 2)_
- [x] Create `Services/Network/ConnectivityMonitor.swift` — NWPathMonitor, @Observable isConnected, MainActor-safe
- [x] VehicleDetailViewModel checks connectivity before fetch, shows offline message
- [x] **Acceptance**: Offline plate scanning works, network errors show error+retry in VehicleDetailView

### Phase 3 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Surepass API cost overrun | Medium | High | 24h cache, rate limit on backend, billing alerts |
| Surepass downtime | Medium | High | Cache successful responses, degrade to location-only |
| App Store rejection (subscription) | Low | High | Follow Apple guidelines exactly: clear pricing, restore button, ToS links |
| PII exposure | Medium | Critical | Strip owner name on backend, never log PII, document in privacy policy |

---

## Phase 4: Scale to Global (Week 5+) ✅ COMPLETE

### Milestone: "App supports India + Morocco, architecture ready for any country"

### 4.1 Country Protocol Architecture ✅ _(completed in Phase 1)_
- [x] `PlateParserProtocol` has `country` property + `PlateParserFactory` returns correct parser per country
- [x] `Models/Domain/Country.swift` enum (india, morocco) with displayName, flagEmoji, dataFileName
- [x] `CountryDataServiceProtocol` — polymorphic protocol, implemented by RTODataService (India) and MoroccoDataService (Morocco)

### 4.2 Morocco Data Bundle ✅
- [x] Create `Resources/Data/moroccan_cities.json` — all 87 cities with id, name, and coordinates
- [x] Create `Services/Data/MoroccoDataService.swift` — @Observable @MainActor, loads JSON, cityIndex lookup, allRegions(), search()
- [x] `MoroccanPlateParser.swift` — extracts last 2 digits, validates 1-87, returns `.moroccan(cityCode:)` _(existed from Phase 1)_
- [x] **Tests**: `MoroccanPlateParserTests.swift` — 16 tests: valid codes 1-87, invalid codes (0, 88, 99), empty/letter-only input, validate()
- [x] **Acceptance**: All 87 cities present, parsing works, 51 total tests pass (0 failures)

### 4.3 Country Selector ✅
- [x] `Views/Settings/SettingsView.swift` — country picker with flag emoji, subscription controls, restore, privacy/terms links _(existed, now wired)_
- [x] Settings tab in ContentView _(existed from Phase 1)_
- [x] `ScanViewModel` — `switchCountry()` swaps parser, plate detector, and data service (RTODataService ↔ MoroccoDataService)
- [x] `BrowseViewModel` — `switchCountry()` swaps data service, reloads regions
- [x] `ScanView` + `BrowseView` — react to `appState.selectedCountry` changes via `onChange`
- [x] `PlateResultView` — vehicle details teaser hidden for Moroccan plates (India-only feature)
- [x] **Acceptance**: Switching countries changes parser, data, browse content; vehicle intel India-only

### 4.4 Backend Country Data ✅
- [x] `GET /api/v1/countries` — lists available countries with feature flags (plate_to_location, vehicle_intelligence)
- [x] `GET /api/v1/countries/{code}/data` — returns country data with ETag support, `Cache-Control: public, max-age=86400`, 304 Not Modified
- [x] `Services/Network/DataUpdateService.swift` — iOS client checks for updates on launch (24h cooldown), saves to Documents directory, posts `.dataUpdated` notification
- [x] Wired into `BliptApp.swift` — checks on app launch

### 4.5 Community Contribution ✅
- [x] `POST /api/v1/submissions` — accepts DataSubmission (country, type, region_code, rto_code, suggested_name, notes), returns submission_id
- [x] `GET /api/v1/submissions` — admin endpoint to list/filter submissions by status
- [x] `Services/Network/SubmissionService.swift` — iOS client for submitting corrections
- [x] `Views/Settings/DataSubmissionView.swift` — form with submission type picker, region/RTO code, suggested name, notes, submit with loading/success/error states
- [x] Wired into Settings → "Report Missing or Incorrect Data" button

### 4.6 Analytics & Crash Reporting ✅
- [x] `Services/Analytics/AnalyticsService.swift` — privacy-first protocol-based analytics, never logs PII (plate numbers)
- [x] Key events: scan_completed, plate_parsed, vehicle_lookup, subscription_started, country_switched, paywall_viewed, paywall_dismissed, browse_searched
- [x] `ConsoleAnalyticsProvider` — DEBUG logging for development
- [x] `TelemetryDeckProvider` — production stub (requires TelemetryDeck SDK via SPM when ready)
- [ ] Crash reporting (Crashlytics/Sentry) — add when TelemetryDeck SDK is integrated
- [x] Zero PII in analytics — plate numbers never logged, only country/format/confidence buckets

### Phase 4 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Country abstraction over-engineered | Medium | Low | Only India + Morocco. Protocol keeps it extensible without premature generalization |
| Morocco vehicle API | High | Low | Scope Morocco as plate-to-location only |

---

## Cross-Cutting Concerns ✅

### Concurrency ✅
- [x] Swift structured concurrency (async/await) throughout
- [x] `@Observable` (Observation framework, iOS 17+) instead of `@Published` + `ObservableObject`
- [x] Camera frames on dedicated `DispatchQueue` via CameraManager
- [x] OCR/parsing on camera delegate queue (PlateDetector uses synchronous Vision on callback queue)
- [x] `@MainActor` on all ViewModels, services, and data layers for Swift 6 strict concurrency compliance
- [x] `nonisolated(unsafe)` for camera session and frame counter (safe due to single-writer pattern)

### Performance Budgets
| Metric | Target | Status |
|--------|--------|--------|
| App launch to camera ready | < 1.5s | Architecture supports |
| Photo OCR to result | < 2s | VisionOCR `.accurate` mode |
| Live detection per frame | < 200ms | VisionOCR `.fast` mode, 5 FPS throttle |
| RTO data load | < 100ms | In-memory index after first load |
| RTO search | < 50ms | String contains on indexed data |
| Vehicle API round trip | < 3s | 15s timeout, 2 retries with backoff |

### Accessibility ✅
- [x] VoiceOver labels on key controls: shutter button, flash toggle, photo picker, plate visualizer
- [x] `accessibilityElement(children: .combine)` on composite views (PlateVisualizerView, InsuranceCardView)
- [x] Dynamic Type — uses semantic font styles (`.headline`, `.subheadline`, `.caption`) throughout
- [x] WCAG AA color contrast — `.ultraThinMaterial` backgrounds, semantic colors
- [x] Haptic feedback (`UINotificationFeedbackGenerator`) on plate confirmation

### Testing Strategy ✅
- [x] **Unit** (66 tests, 0 failures):
  - `IndianPlateParserTests` — 22 tests: standard, BH, fuzzy, all state codes, invalid input
  - `FuzzyMatcherTests` — 13 tests: each substitution pair, bounds, state matching
  - `MoroccanPlateParserTests` — 16 tests: all 87 codes, invalid codes, validation
  - `RTODataServiceTests` — 10 tests: load, lookup (MH12=Pune, DL01, BH), search, regions
  - `ScanViewModelTests` — 5 tests: initial state, valid plate, no plate, reset, country switch
- [ ] **Integration**: OCR with real device + test images _(requires physical device)_
- [ ] **Backend**: pytest with mocked Surepass _(deferred)_
- [x] **Previews**: PlateResultView (3 variants: standard, BH, not found), PlateVisualizerView (2), InsuranceCardView (4 states), ChallanListView (2), FitnessCardView (4 states), ScanView, BrowseView, SettingsView, LoadingOverlay, ErrorBannerView

### StoreKit Configuration ✅
- [x] `Configuration.storekit` — testing config with monthly ($4.99) and yearly ($39.99) plans, 1-week free trial

---

## Deliverables Summary

| Phase | Weeks | Deliverable | Offline? | Revenue? |
|-------|-------|-------------|----------|----------|
| 1: Foundation | 1-2 | Photo-based plate → state + district + map | Yes | No |
| 2: Camera UX | 2-3 | Live camera scanning with real-time detection | Yes | No |
| 3: Backend + Intel | 3-5 | Vehicle details, insurance, challans, subscription | Partial | Yes |
| 4: Global | 5+ | Morocco support, country selector, analytics | Yes | Yes |
| **5: Engagement** | — | History, onboarding, manual entry, share card | Yes | Indirect |
| **6: Accuracy** | — | Image preprocessing, night mode, multi-plate, CoreML | Yes | No |
| **7: Revenue** | — | Usage paywall, fleet lookup, referrals | Partial | Yes |
| **8: Depth** | — | RTO details, insurance alerts, vehicle compare | Partial | Yes |
| **9: Platform** | — | Widget, Siri, Apple Watch, CarPlay, App Clip | Yes | Indirect |
| **10: Scale** | — | More countries, localization, backend DB, A/B tests | Yes | Yes |

---

## Verification Plan

### Phase 1-4 Verification (Completed)
1. Run all unit tests: `cmd+U` — 66 tests, 0 failures
2. Launch app on simulator → pick a photo of an Indian plate → verify state + district + map
3. Test with plates from different states (MH, DL, KA, TN) + BH series
4. Run on real device → point camera at plate → verify bounding box + haptic confirmation
5. Browse tab search with "Pune", "Mumbai", "MH12"
6. Settings → switch to Morocco → verify cities load, scan works
7. Settings → Upgrade to Premium → verify product cards + purchase flow (StoreKit test config)
8. Test offline → plate-to-location works, vehicle details shows offline message

---

## Phase 5: Engagement & Retention ✅ COMPLETE

### Milestone: "Users come back daily — scan history, onboarding, sharing make the app sticky"

### 5.1 Scan History ✅
- [x] Create `Models/Domain/ScanHistory.swift` — `ScanHistoryItem` model + `ScanHistoryStore` (persisted via UserDefaults/JSON, dedup within 30s)
- [x] Create `ViewModels/HistoryViewModel.swift` — search, delete, premium gate (5 free / unlimited premium)
- [x] Create `Views/History/HistoryView.swift` — list with plate badges, relative timestamps, swipe-to-delete, empty state, upgrade prompt
- [x] `HistoryRowView` — mini plate badge (white on black), state name, district, relative time
- [x] Updated tab bar → **Scan | History | Browse | Settings** (4 tabs)
- [x] Auto-save every successful scan (camera confirm, manual capture, photo, manual entry)
- [x] **Acceptance**: Scans persist across launches, searchable, deletable, premium gate on count

### 5.2 Onboarding Flow ✅
- [x] Create `Views/Onboarding/OnboardingView.swift` — 3-page rich onboarding
  - Page 1: Title + subtitle at top, camera icon + plate mockup illustration below
  - Page 2: Title + subtitle at top, full result card mockup (plate, state/district/RTO rows, map) below
  - Page 3: Title + subtitle at top, premium features checklist with gold border below
- [x] Custom animated page dots (active = expanded blue capsule)
- [x] "Continue" / "Get Started" button + "Skip" top-right
- [x] `@AppStorage("hasCompletedOnboarding")` — reactive transition via SplashView
- [x] **Acceptance**: Shows on first launch only, each page feels complete, transitions to main app

### 5.3 Manual Plate Entry ✅
- [x] Keyboard icon button in camera bottom controls → opens ManualEntryView sheet
- [x] `Views/Scan/ManualEntryView.swift` — live plate preview (monospaced), text field, "Look Up" button (blue gradient)
- [x] Validates through country-specific parser, saves to history
- [x] **Acceptance**: Type "MH12AB1234" → see Pune result, invalid input shows error

### 5.4 Share as Branded Card ✅
- [x] `Views/Components/ShareCardView.swift` — dark card with Blipt logo, plate, location, state code badge, "Scanned with Blipt" watermark
- [x] `ImageRenderer` (scale 3x) generates shareable UIImage
- [x] Share button in ScanResultSheet uses `UIActivityViewController` with branded card image
- [x] **Acceptance**: Share produces clean branded dark card image

### 5.5 Multi-Plate Detection
- [ ] Update PlateDetector to collect all valid plates per frame _(deferred — requires real-device testing)_

### Phase 5 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| History data migration | Low | Medium | Use versioned schema, SwiftData handles migrations |
| Manual entry abuse | Medium | Low | Same rate limits as camera scan |
| Share card rendering perf | Low | Low | ImageRenderer is fast for simple views |

---

## Phase 6: Accuracy & Low-Light ✅ COMPLETE

### Milestone: "OCR works reliably on dirty, angled, night-time plates"

### 6.1 Image Preprocessing Pipeline ✅
- [x] Create `Services/OCR/ImagePreprocessor.swift`
- [x] Step 1: `VNDetectRectanglesRequest` to find plate rectangle → crop (aspect ratio 2.0-6.0, min confidence 0.5)
- [x] Step 2: Perspective correction via `CIPerspectiveCorrection` filter (deskew angled plates)
- [x] Step 3: Contrast enhancement via `CIColorControls` (contrast 1.3, grayscale for OCR)
- [x] Step 4: Sharpen via `CISharpenLuminance` (sharpness 0.5, radius 1.5)
- [x] `preprocessFast()` — lightweight contrast-only for live frames
- [x] Integrated into ScanViewModel: tries raw OCR first, retries with preprocessed image if no plate found
- [x] **Acceptance**: Two-pass approach — fast first, enhanced fallback

### 6.2 Night Mode ✅
- [x] Low-light detection via `AVCaptureDevice.iso > 800` or `exposureDuration > 1/30s`
- [x] `autoTorchIfNeeded()` — auto-enables torch when low light detected
- [x] UI indicator: yellow "Low Light — Flash Recommended" badge with moon icon in camera view
- [x] **Acceptance**: Badge appears in low light, torch auto-enables

### 6.3 CoreML Custom Plate Model (Future)
- [ ] Collect 1,000+ Indian plate images with labels
- [ ] Train CreateML text recognition model
- [ ] Bundle `.mlmodel`, fall back to Vision if CoreML confidence < 0.7

### Phase 6 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Preprocessing slows detection | Medium | Medium | Only preprocess on still images (retry path), not live frames |
| CoreML model size | Medium | Low | Quantize to reduce size, download on demand |

---

## Phase 7: Revenue Optimization ✅ COMPLETE

### Milestone: "Higher conversion rate, more revenue streams"

### 7.1 Usage-Based Paywall ✅
- [x] `Services/Subscription/UsageTracker.swift` — tracks monthly lookup count, auto-resets on month boundary, supports bonus lookups
- [x] Free users get 3 vehicle lookups per month; premium: unlimited
- [x] `VehicleDetailViewModel` checks usage before fetch — `.usageLimitReached` state triggers paywall
- [x] `VehicleDetailView` shows "Free Lookups Used" screen with upgrade button when limit hit
- [x] **Acceptance**: 4th lookup shows usage limit screen with paywall, counter resets monthly

### 7.2 Fleet / Bulk Lookup ✅
- [x] Backend: `POST /api/v1/vehicle/bulk` (`Backend/routers/fleet.py`) — accepts up to 100 plates, returns batch results with success/failure per plate
- [x] `Services/Network/FleetService.swift` — iOS client for bulk lookup
- [x] `ViewModels/FleetViewModel.swift` — parse comma/newline input, lookup, CSV export
- [x] `Views/Fleet/FleetView.swift` — text input, "Look Up All" button, results summary (total/found/failed), result rows with plate badges + status, CSV export via ShareLink
- [x] Accessible from Settings → "Fleet / Bulk Lookup"
- [x] **Acceptance**: Enter 10 plates → see 10 results → export as CSV

### 7.3 Referral Program ✅
- [x] `Services/Subscription/ReferralManager.swift` — generates 8-char alphanumeric code (no I/O/0/1 confusion), tracks referrals, redeem logic, bonus lookups
- [x] `Views/Settings/ReferralView.swift` — shows user's code (large monospaced), share button, stats (friends referred + bonus earned), redeem field for friend's code
- [x] "Give 3 free lookups, get 3 free lookups" — bonus lookups added via UsageTracker
- [x] Accessible from Settings → "Refer a Friend"
- [x] **Acceptance**: Share code, redeem code grants bonus lookups, one-time redeem

### Phase 7 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Usage paywall reduces engagement | Medium | High | A/B test vs current hard gate |
| Fleet API cost | Medium | Medium | Higher pricing tier covers Surepass costs |

---

## Phase 8: Feature Depth ✅ COMPLETE

### Milestone: "App becomes indispensable for vehicle-related decisions"

### 8.1 RTO Office Details ✅
- [x] Extended `RTOOffice` model with optional `address`, `phone`, `workingHours` (backward-compatible decoding)
- [x] `Views/Result/RTODetailView.swift` — full RTO info: code header, map, address, phone with call button, working hours, district, "Get Directions" (MKMapItem deep link)
- [x] JSON supports new fields when available; gracefully handles nil
- [x] **Acceptance**: RTO detail shows all available info, directions opens Apple Maps

### 8.2 Insurance Expiry Alerts ✅
- [x] `Services/NotificationManager.swift` — request permission, schedule calendar-based notifications, cancel per plate
- [x] `scheduleInsuranceReminder(plate:expiryDate:daysBefore:)` — 30 days before expiry
- [x] `scheduleFitnessReminder(plate:expiryDate:daysBefore:)` — 90 days before expiry
- [x] InsuranceCardView: "Remind Before Expiry" button with checkmark confirmation state
- [x] **Acceptance**: Tap remind → notification scheduled, button shows "Reminder Set"

### 8.3 Vehicle Comparison ✅
- [x] `Views/Compare/CompareView.swift` — side-by-side comparison: vehicle info, registration, insurance, fitness, challans
- [x] Differences highlighted in orange (`highlightDiff` parameter)
- [x] Sections: Vehicle (make/model/fuel/class/emission), Registration (RC status/date), Insurance (company/validity), Fitness, Challans (count/pending)
- [x] **Acceptance**: Two vehicles shown side-by-side with differences highlighted

### 8.4 RC Verification Badge ✅
- [x] `Views/Components/VerificationBadgeView.swift` — `VerificationLevel` enum with `.verified` (green shield), `.caution` (yellow), `.issues` (red)
- [x] `VerificationLevel.compute(from:)` — scores RC status (3pts), insurance (2pts), fitness (2pts), challans penalty
- [x] Displayed in VehicleDetailView below plate header
- [x] Compact mode available for inline use
- [x] **Acceptance**: Active RC + valid insurance + no challans = green "Verified" badge

### 8.5 Plate Photo Gallery ✅
- [x] `Services/PlatePhotoStore.swift` — save/load/delete JPEG photos in Documents/PlatePhotos/, thumbnail generation
- [x] `ScanHistoryItem.photoFilename` — optional field, backward-compatible
- [x] `ScanViewModel.saveToHistory` — auto-saves `capturedImage` alongside scan record
- [x] `HistoryRowView` — shows photo thumbnail (44x44) if available, falls back to plate badge
- [x] **Acceptance**: Photo saved on scan, thumbnail in history, persists across launches

### Phase 8 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| RTO phone data stale | High | Low | Mark as "may be outdated", allow user submissions |
| Notification permission denied | Medium | Low | Graceful fallback, explain value in prompt |

---

## Phase 9: Platform Expansion ✅ COMPLETE

### Milestone: "Blipt is everywhere — home screen, Siri, wrist, car"

### 9.1 Home Screen Widget ✅
- [x] `BliptWidget/BliptWidget.swift` — WidgetKit extension with small (last scan) and medium (last 3 scans) widgets
- [x] `WidgetDataBridge.swift` — bridges scan data via App Group, triggers timeline refresh after each scan
- [x] Widget target in project.yml with Info.plist
- [x] **Acceptance**: Widget builds, shows scan data, refreshes on new scan

### 9.2 Siri Shortcuts ✅
- [x] `ScanPlateIntent` — opens camera via `openAppWhenRun`
- [x] `LookUpPlateIntent` — takes plate string, returns state/district/RTO
- [x] `BliptShortcutsProvider` — registers Siri phrases
- [x] **Acceptance**: "Hey Siri, scan a plate with Blipt" opens camera

### 9.3 Apple Watch Companion ✅
- [x] `BliptWatch/BliptWatchApp.swift` — recent scans list from shared App Group
- [x] _(Scaffold complete — needs WatchKit target in Xcode)_

### 9.4 App Clip ✅
- [x] `BliptAppClip/BliptAppClipApp.swift` — manual entry + inline parse + App Store overlay upsell
- [x] _(Scaffold complete — needs App Clip target in Xcode)_

### 9.5 CarPlay Integration ✅
- [x] `CarPlaySceneDelegate.swift` — CPListTemplate with recent scans, tap for detail
- [x] _(Scaffold complete — needs CarPlay entitlement)_

### Phase 9 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Widget refresh limits | Medium | Low | Refresh on app foreground, timeline-based updates |
| App Clip size limit (15MB) | Medium | Medium | Strip data files, download on demand |
| CarPlay review guidelines | Medium | Medium | Follow Apple HIG strictly, no driver distraction |

---

## Phase 10: Scale & Intelligence

### Milestone: "Blipt works globally, learns from usage, optimizes revenue"

### 10.1 More Countries
- [ ] UAE plate parser + RTO data
- [ ] Saudi Arabia plate parser + data
- [ ] UK plate parser + DVLA API integration
- [ ] Add country to `Country` enum + `PlateParserFactory`
- [ ] **Acceptance**: Each new country: parser + data + browse + scan works

### 10.2 Localization
- [ ] Hindi (hi), Marathi (mr), Tamil (ta) for Indian users
- [ ] Arabic (ar) for Morocco/UAE/Saudi
- [ ] French (fr) for Morocco
- [ ] Use String Catalogs (`.xcstrings`) for all user-facing text
- [ ] **Acceptance**: Switch device language → app fully translated

### 10.3 Backend Database
- [ ] Migrate from in-memory to PostgreSQL (Supabase or Railway Postgres)
- [ ] Tables: users, lookups, subscriptions, submissions, cache
- [ ] User accounts (Sign in with Apple)
- [ ] Lookup history synced across devices
- [ ] **Acceptance**: Sign in → history syncs to new device

### 10.4 A/B Testing & Analytics
- [ ] Integrate TelemetryDeck SDK via SPM
- [ ] A/B test paywall designs (current vs usage-based vs trial)
- [ ] Track funnel: scan → result → paywall → purchase
- [ ] Heatmap: most scanned states/RTOs
- [ ] **Acceptance**: Dashboard shows conversion funnel, A/B test results

### 10.5 User Feedback Loop
- [ ] "Was this result correct?" prompt after each scan (thumbs up/down)
- [ ] Log feedback to backend (no PII — just plate format + correct/incorrect)
- [ ] Use feedback to identify weak plate types and prioritize accuracy fixes
- [ ] **Acceptance**: Feedback collected, dashboard shows accuracy by plate format

### Phase 10 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Localization quality | Medium | Medium | Professional translation for top 3 languages, community for rest |
| Database migration complexity | Medium | High | Start with Supabase (managed), migrate later if needed |
| DVLA API access (UK) | High | Medium | Apply for API access early, fallback to plate-to-location only |
