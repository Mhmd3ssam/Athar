import UIKit

enum AtharImageStoreError: Error {
    case encodeFailed
}

enum AtharImageStore {
    private static let directoryName = "DocumentImages"

    static func save(image: UIImage, documentID: UUID) throws -> (imageFilename: String, thumbnailFilename: String) {
        let directory = try imageDirectory()
        let imageFilename = "\(documentID.uuidString).jpg"
        let thumbnailFilename = "\(documentID.uuidString)-thumb.jpg"
        let imageURL = directory.appendingPathComponent(imageFilename)
        let thumbnailURL = directory.appendingPathComponent(thumbnailFilename)

        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw AtharImageStoreError.encodeFailed
        }

        let thumbnail = makeThumbnail(from: image)
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.82) else {
            throw AtharImageStoreError.encodeFailed
        }

        try imageData.write(to: imageURL, options: .atomic)

        do {
            try thumbnailData.write(to: thumbnailURL, options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: imageURL)
            throw error
        }

        return (imageFilename, thumbnailFilename)
    }

    static func image(named filename: String) -> UIImage? {
        guard let directory = try? imageDirectory() else { return nil }
        return UIImage(contentsOfFile: directory.appendingPathComponent(filename).path)
    }

    static func delete(imageFilename: String, thumbnailFilename: String?) {
        guard let directory = try? imageDirectory() else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(imageFilename))
        if let thumbnailFilename {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(thumbnailFilename))
        }
    }

    static func storageUsageBytes() -> Int64 {
        guard let directory = try? imageDirectory() else { return 0 }
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        return urls.reduce(into: Int64(0)) { total, url in
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize else { return }
            total += Int64(size)
        }
    }

    private static func imageDirectory() throws -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = root.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private static func makeThumbnail(from image: UIImage) -> UIImage {
        let target = CGSize(width: 260, height: 360)
        let imageRatio = image.size.width / max(image.size.height, 1)
        let targetRatio = target.width / target.height

        let size: CGSize
        if imageRatio > targetRatio {
            size = CGSize(width: target.width, height: target.width / imageRatio)
        } else {
            size = CGSize(width: target.height * imageRatio, height: target.height)
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
