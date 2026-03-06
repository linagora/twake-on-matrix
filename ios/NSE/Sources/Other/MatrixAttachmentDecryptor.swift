import CommonCrypto
import CryptoKit
import Foundation

/// Decrypts Matrix encrypted file attachments (EncryptedFile spec, MSC1767).
///
/// Matrix encrypts media with AES-256-CTR (no padding).
/// The `file` object in event content carries: url, key.k (AES key, base64url),
/// iv (16-byte counter block, base64), and hashes.sha256 (integrity check, base64).
enum MatrixAttachmentDecryptor {

    // MARK: - Errors

    enum DecryptionError: Error {
        case invalidBase64
        case invalidKeyLength
        case invalidIVLength
        case hashMismatch
        case aesFailed(CCCryptorStatus)
    }

    // MARK: - Entry point

    /// Decrypts a Matrix encrypted file attachment.
    ///
    /// - Parameters:
    ///   - encryptedData: Raw encrypted bytes fetched from the homeserver.
    ///   - keyBase64url: `file.key.k` — base64url-encoded 32-byte AES-256 key.
    ///   - ivBase64: `file.iv` — base64-encoded 16-byte AES-CTR counter block.
    ///   - sha256Base64: `file.hashes.sha256` — base64-encoded SHA-256 of the encrypted data.
    /// - Returns: Decrypted plaintext `Data`.
    static func decrypt(
        encryptedData: Data,
        keyBase64url: String,
        ivBase64: String,
        sha256Base64: String
    ) throws -> Data {
        // Verify SHA-256 integrity before decrypting.
        let expectedHash = try decodeBase64(sha256Base64)
        let computedHash = Data(SHA256.hash(data: encryptedData))
        guard computedHash == Data(expectedHash) else {
            throw DecryptionError.hashMismatch
        }

        let keyBytes = try decodeBase64(keyBase64url)
        guard keyBytes.count == 32 else { throw DecryptionError.invalidKeyLength }

        let ivBytes = try decodeBase64(ivBase64)
        guard ivBytes.count == 16 else { throw DecryptionError.invalidIVLength }

        return try aesCTRDecrypt(data: encryptedData, key: Data(keyBytes), iv: Data(ivBytes))
    }

    // MARK: - AES-256-CTR decryption

    private static func aesCTRDecrypt(data: Data, key: Data, iv: Data) throws -> Data {
        var cryptor: CCCryptorRef?
        let createStatus = key.withUnsafeBytes { keyPtr in
            iv.withUnsafeBytes { ivPtr in
                CCCryptorCreateWithMode(
                    CCOperation(kCCDecrypt),
                    CCMode(kCCModeCTR),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCPadding(ccNoPadding),
                    ivPtr.baseAddress,
                    keyPtr.baseAddress, kCCKeySizeAES256,
                    nil, 0, 0,
                    CCModeOptions(kCCModeOptionCTR_BE),
                    &cryptor)
            }
        }
        guard createStatus == kCCSuccess, let cryptor else {
            throw DecryptionError.aesFailed(createStatus)
        }
        defer { CCCryptorRelease(cryptor) }

        var outBuf = [UInt8](repeating: 0, count: data.count)
        var moved = 0
        let updateStatus = data.withUnsafeBytes { dataPtr in
            CCCryptorUpdate(cryptor, dataPtr.baseAddress, data.count, &outBuf, outBuf.count, &moved)
        }
        guard updateStatus == kCCSuccess else {
            throw DecryptionError.aesFailed(updateStatus)
        }
        return Data(outBuf.prefix(moved))
    }

    // MARK: - Helpers

    /// Decodes standard base64 and base64url (url-safe, with or without padding).
    private static func decodeBase64(_ input: String) throws -> [UInt8] {
        var b64 = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let rem = b64.count % 4
        if rem != 0 { b64 += String(repeating: "=", count: 4 - rem) }
        guard let data = Data(base64Encoded: b64) else {
            throw DecryptionError.invalidBase64
        }
        return Array(data)
    }
}
