import Compression
import Foundation
import OSLog

/// Decodes Mozilla's JSONLZ4 session store format used by Zen Browser.
nonisolated enum JSONLZ4Decoder {
    private static let magic = Data("mozLz40\0".utf8)

    enum DecoderError: Error, CustomStringConvertible {
        case invalidMagic
        case invalidHeader
        case decompressionFailed
        case invalidJSON

        var description: String {
            switch self {
            case .invalidMagic: "invalid magic bytes"
            case .invalidHeader: "invalid header"
            case .decompressionFailed: "decompression failed"
            case .invalidJSON: "invalid JSON"
            }
        }
    }

    /// Decodes a JSONLZ4 file into a JSON dictionary, retrying briefly when Zen is mid-write.
    static func decode(contentsOf url: URL) throws -> [String: Any] {
        var lastError: Error = DecoderError.decompressionFailed

        for attempt in 0 ..< 3 {
            if attempt > 0 {
                Thread.sleep(forTimeInterval: 0.2)
            }

            do {
                let data = try Data(contentsOf: url)
                return try decode(data: data)
            } catch {
                lastError = error
                AppLogger.debug.debug(
                    "JSONLZ4 decode attempt \(attempt + 1, privacy: .public) failed: \(String(describing: error), privacy: .public)"
                )
            }
        }

        throw lastError
    }

    /// Decodes JSONLZ4 data into a JSON dictionary.
    static func decode(data: Data) throws -> [String: Any] {
        guard data.count > 12 else { throw DecoderError.invalidHeader }
        guard data.prefix(8) == magic else { throw DecoderError.invalidMagic }

        let uncompressedSize = Int(data.withUnsafeBytes { buffer in
            UInt32(littleEndian: buffer.loadUnaligned(fromByteOffset: 8, as: UInt32.self))
        })

        guard uncompressedSize > 0, uncompressedSize <= 64 * 1024 * 1024 else {
            throw DecoderError.invalidHeader
        }

        let payload = data.subdata(in: 12 ..< data.count)
        let decompressed = try decompressPayload(payload, expectedOutputSize: uncompressedSize)

        let object = try JSONSerialization.jsonObject(with: decompressed)
        guard let dictionary = object as? [String: Any] else {
            throw DecoderError.invalidJSON
        }
        return dictionary
    }

    /// Decompresses payload using Mozilla's JSONLZ4 rules.
    private static func decompressPayload(_ payload: Data, expectedOutputSize: Int) throws -> Data {
        // Mozilla stores uncompressed JSON when compression does not reduce size.
        if payload.count >= expectedOutputSize {
            let uncompressed = payload.prefix(expectedOutputSize)
            if isValidJSONObjectPrefix(uncompressed) {
                return Data(uncompressed)
            }
        }

        if let decompressed = decompressLZ4Raw(source: payload, expectedOutputSize: expectedOutputSize) {
            return decompressed
        }

        throw DecoderError.decompressionFailed
    }

    private static func decompressLZ4Raw(source: Data, expectedOutputSize: Int) -> Data? {
        var destination = Data(count: expectedOutputSize)

        let decodedByteCount: Int = destination.withUnsafeMutableBytes { destinationBuffer in
            source.withUnsafeBytes { sourceBuffer in
                guard let destinationPointer = destinationBuffer.bindMemory(to: UInt8.self).baseAddress,
                      let sourcePointer = sourceBuffer.bindMemory(to: UInt8.self).baseAddress else {
                    return 0
                }

                return compression_decode_buffer(
                    destinationPointer,
                    expectedOutputSize,
                    sourcePointer,
                    source.count,
                    nil,
                    COMPRESSION_LZ4_RAW
                )
            }
        }

        guard decodedByteCount > 0 else { return nil }
        destination.count = decodedByteCount
        return destination
    }

    private static func isValidJSONObjectPrefix(_ data: Data.SubSequence) -> Bool {
        guard let first = data.first else { return false }
        return first == UInt8(ascii: "{") || first == UInt8(ascii: "[")
    }
}