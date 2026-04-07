import CoreImage
import Vision

/// Preprocesses plate images to improve OCR accuracy.
/// Steps: detect rectangle → crop → deskew → enhance contrast → sharpen.
final class ImagePreprocessor: Sendable {
    private let context = CIContext()

    /// Full preprocessing pipeline for still images.
    func preprocess(_ cgImage: CGImage) async -> CGImage {
        var ciImage = CIImage(cgImage: cgImage)

        // Step 1: Try to detect and crop plate rectangle
        if let cropped = await detectAndCropPlate(from: cgImage) {
            ciImage = CIImage(cgImage: cropped)
        }

        // Step 2: Enhance contrast
        ciImage = enhanceContrast(ciImage)

        // Step 3: Sharpen
        ciImage = sharpen(ciImage)

        // Convert back to CGImage
        return context.createCGImage(ciImage, from: ciImage.extent) ?? cgImage
    }

    /// Lightweight preprocessing for live camera frames (no rectangle detection).
    func preprocessFast(_ cgImage: CGImage) -> CGImage {
        var ciImage = CIImage(cgImage: cgImage)
        ciImage = enhanceContrast(ciImage)
        return context.createCGImage(ciImage, from: ciImage.extent) ?? cgImage
    }

    // MARK: - Rectangle Detection + Crop

    private func detectAndCropPlate(from image: CGImage) async -> CGImage? {
        await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                guard error == nil,
                      let results = request.results as? [VNRectangleObservation],
                      let rect = results.first else {
                    continuation.resume(returning: nil)
                    return
                }

                // Crop to detected rectangle
                let ciImage = CIImage(cgImage: image)
                let imageSize = ciImage.extent.size

                // Convert normalized coordinates to pixel coordinates
                let topLeft = CGPoint(x: rect.topLeft.x * imageSize.width, y: rect.topLeft.y * imageSize.height)
                let topRight = CGPoint(x: rect.topRight.x * imageSize.width, y: rect.topRight.y * imageSize.height)
                let bottomLeft = CGPoint(x: rect.bottomLeft.x * imageSize.width, y: rect.bottomLeft.y * imageSize.height)
                let bottomRight = CGPoint(x: rect.bottomRight.x * imageSize.width, y: rect.bottomRight.y * imageSize.height)

                // Perspective correction
                let corrected = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
                    "inputTopLeft": CIVector(cgPoint: topLeft),
                    "inputTopRight": CIVector(cgPoint: topRight),
                    "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                    "inputBottomRight": CIVector(cgPoint: bottomRight),
                ])

                let ctx = CIContext()
                let result = ctx.createCGImage(corrected, from: corrected.extent)
                continuation.resume(returning: result)
            }

            request.minimumAspectRatio = 2.0  // Plates are wider than tall
            request.maximumAspectRatio = 6.0
            request.minimumSize = 0.1
            request.maximumObservations = 1
            request.minimumConfidence = 0.5

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Contrast Enhancement

    private func enhanceContrast(_ image: CIImage) -> CIImage {
        image.applyingFilter("CIColorControls", parameters: [
            kCIInputContrastKey: 1.3,
            kCIInputBrightnessKey: 0.05,
            kCIInputSaturationKey: 0.0, // Grayscale helps OCR
        ])
    }

    // MARK: - Sharpen

    private func sharpen(_ image: CIImage) -> CIImage {
        image.applyingFilter("CISharpenLuminance", parameters: [
            kCIInputSharpnessKey: 0.5,
            kCIInputRadiusKey: 1.5,
        ])
    }
}
