import SwiftUI
import PhotosUI

struct ScanView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ScanViewModel()
    @State private var showResult = false
    @State private var showFullResult = false
    @State private var showManualEntry = false

    var body: some View {
        ZStack {
            // Camera viewfinder (fills entire screen)
            cameraLayer

            // Guide overlay + plate overlay
            overlayLayer

            // Top controls
            VStack {
                topBar
                Spacer()
            }

            // Bottom controls
            VStack {
                Spacer()
                bottomControls
            }

            // Processing overlay
            if viewModel.scanState == .processing {
                processingOverlay
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .sheet(isPresented: $showResult) {
            resultSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showFullResult) {
            if case .result(let plate, let location) = viewModel.scanState {
                PlateResultView(
                    plate: plate,
                    location: location,
                    image: viewModel.capturedImage
                )
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView(
                parser: PlateParserFactory.parser(for: appState.selectedCountry),
                dataService: viewModel.country == .india ? RTODataService() : MoroccoDataService() as CountryDataServiceProtocol,
                historyStore: viewModel.historyStore,
                country: viewModel.country
            )
        }
        .alert("Scan Error", isPresented: .init(
            get: { if case .error = viewModel.scanState { return true } else { return false } },
            set: { if !$0 { viewModel.resumeCamera() } }
        )) {
            Button("OK") { viewModel.resumeCamera() }
        } message: {
            if case .error(let msg) = viewModel.scanState {
                Text(msg)
            }
        }
        .onChange(of: viewModel.plateDetector.isConfirmed) { _, confirmed in
            if confirmed {
                triggerHaptic()
                viewModel.confirmDetection()
                showResult = true
            }
        }
        .onChange(of: viewModel.scanState) { _, newState in
            if case .result = newState, !viewModel.plateDetector.isConfirmed {
                // Photo-based result
                showResult = true
            }
        }
        .task {
            await viewModel.loadDataIfNeeded()
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .onChange(of: appState.selectedCountry) { _, newCountry in
            viewModel.switchCountry(newCountry)
            viewModel.startCamera()
        }
    }

    // MARK: - Camera Layer

    private var cameraLayer: some View {
        Group {
            switch viewModel.cameraManager.status {
            case .running, .authorized:
                CameraPreviewView(session: viewModel.cameraManager.session)
            case .denied:
                cameraDeniedView
            case .failed(let msg):
                cameraErrorView(msg)
            default:
                Color.black
            }
        }
    }

    // MARK: - Overlay Layer

    private var overlayLayer: some View {
        GeometryReader { geometry in
            ZStack {
                // Guide corners that pulse
                CameraGuideView()

                // Plate detection overlay
                PlateOverlayView(
                    detection: viewModel.plateDetector.currentDetection,
                    isConfirmed: viewModel.plateDetector.isConfirmed,
                    geometrySize: geometry.size
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Flash toggle
            Button {
                viewModel.cameraManager.toggleFlash()
            } label: {
                Image(systemName: viewModel.cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash")
                    .font(.title3)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(viewModel.cameraManager.isFlashOn ? "Turn off flash" : "Turn on flash")

            Spacer()

            // App title
            HStack(spacing: 6) {
                BliptLogoView(size: 22, animated: false)
                Text("Blipt")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 54)
        .foregroundStyle(.white)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Hint text
            if viewModel.plateDetector.currentDetection == nil && !viewModel.plateDetector.isConfirmed {
                Text("Point camera at a license plate")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())
                    .transition(.opacity)
            }

            HStack(spacing: 40) {
                // Photo library
                PhotosPicker(
                    selection: $viewModel.selectedPhoto,
                    matching: .images
                ) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .foregroundStyle(.white)
                        .accessibilityLabel("Choose photo from library")
                }
                .onChange(of: viewModel.selectedPhoto) {
                    viewModel.scanMode = .photo
                    Task { await viewModel.processSelectedPhoto() }
                }

                // Manual shutter button
                Button {
                    viewModel.manualCapture()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .accessibilityLabel("Capture plate")

                // Manual entry
                Button {
                    showManualEntry = true
                } label: {
                    Image(systemName: "keyboard")
                        .font(.title2)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Type plate number manually")
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                Text("Scanning plate...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .ignoresSafeArea()
    }

    // MARK: - Result Sheet

    @ViewBuilder
    private var resultSheet: some View {
        if case .result(let plate, let location) = viewModel.scanState {
            ScanResultSheet(
                plate: plate,
                location: location,
                image: viewModel.capturedImage,
                onScanAnother: {
                    showResult = false
                    viewModel.resumeCamera()
                },
                onViewDetails: {
                    showResult = false
                    showFullResult = true
                }
            )
        }
    }

    // MARK: - Error States

    private var cameraDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Camera Access Required")
                .font(.title3.bold())
            Text("Enable camera access in Settings to scan license plates.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }

    private func cameraErrorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Camera Error")
                .font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }

    // MARK: - Haptic

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Camera Guide View

struct CameraGuideView: View {
    @State private var isPulsing = false

    var body: some View {
        GeometryReader { geometry in
            let guideWidth = geometry.size.width * 0.8
            let guideHeight: CGFloat = 80
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2

            ZStack {
                // Semi-transparent overlay with cutout
                Rectangle()
                    .fill(.black.opacity(0.3))
                    .reverseMask {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: guideWidth, height: guideHeight)
                            .position(x: centerX, y: centerY)
                    }

                // Corner brackets
                let corners = guideCorners(
                    center: CGPoint(x: centerX, y: centerY),
                    width: guideWidth,
                    height: guideHeight
                )

                ForEach(0..<4, id: \.self) { index in
                    CornerBracket(
                        position: corners[index],
                        corner: Corner.allCases[index]
                    )
                }
                .opacity(isPulsing ? 0.6 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isPulsing
                )
            }
        }
        .onAppear { isPulsing = true }
        .allowsHitTesting(false)
    }

    private func guideCorners(center: CGPoint, width: CGFloat, height: CGFloat) -> [CGPoint] {
        [
            CGPoint(x: center.x - width / 2, y: center.y - height / 2), // topLeft
            CGPoint(x: center.x + width / 2, y: center.y - height / 2), // topRight
            CGPoint(x: center.x - width / 2, y: center.y + height / 2), // bottomLeft
            CGPoint(x: center.x + width / 2, y: center.y + height / 2), // bottomRight
        ]
    }
}

enum Corner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
}

struct CornerBracket: View {
    let position: CGPoint
    let corner: Corner

    private let length: CGFloat = 24
    private let thickness: CGFloat = 3

    var body: some View {
        ZStack {
            // Horizontal arm
            Rectangle()
                .fill(.white)
                .frame(width: length, height: thickness)
                .offset(x: hOffsetX, y: 0)

            // Vertical arm
            Rectangle()
                .fill(.white)
                .frame(width: thickness, height: length)
                .offset(x: 0, y: vOffsetY)
        }
        .position(position)
    }

    private var hOffsetX: CGFloat {
        switch corner {
        case .topLeft, .bottomLeft: length / 2
        case .topRight, .bottomRight: -length / 2
        }
    }

    private var vOffsetY: CGFloat {
        switch corner {
        case .topLeft, .topRight: length / 2
        case .bottomLeft, .bottomRight: -length / 2
        }
    }
}

// MARK: - Reverse Mask Modifier

extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}

#Preview {
    ScanView()
        .environment(AppState())
}
