import UIKit

/// Saves and retrieves captured plate photos alongside scan history.
@MainActor
final class PlatePhotoStore {
    static let shared = PlatePhotoStore()

    private let directory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("PlatePhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// Save a photo for a scan. Returns the file name.
    func save(_ image: UIImage, for scanID: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        let filename = "\(scanID.uuidString).jpg"
        let url = directory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return filename
        } catch {
            return nil
        }
    }

    /// Load a photo by filename.
    func load(filename: String) -> UIImage? {
        let url = directory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Delete a photo.
    func delete(filename: String) {
        let url = directory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    /// Get thumbnail (downscaled) for list display.
    func thumbnail(filename: String, size: CGFloat = 60) -> UIImage? {
        guard let image = load(filename: filename) else { return nil }
        let scale = size / max(image.size.width, image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return thumbnail
    }
}
