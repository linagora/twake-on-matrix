import CommonCrypto
import CryptoKit
import Foundation

/// Pure-Swift Megolm (m.megolm.v1.aes-sha2) decryptor.
///
/// **Algorithm summary**
/// 1. Parse the session key (v0x02 from an `m.room_key` event) to get the
///    initial ratchet state (R0..R3) and its starting index.
/// 2. Parse the Megolm message binary blob to extract the message index and
///    AES ciphertext.
/// 3. Advance the ratchet from the session start index to the message index.
/// 4. Derive AES-256 key, HMAC-SHA256 key and AES-CBC IV via HKDF-SHA256
///    (salt = 32 zero bytes, info = "MEGOLM_KEYS", output = 80 bytes).
/// 5. Verify the 8-byte MAC that trails the message blob.
/// 6. Decrypt with AES-256-CBC (PKCS7 padding).
/// 7. Return the plaintext JSON string.
enum MegolmDecryptor {

    // MARK: - Errors

    enum DecryptionError: Error {
        case invalidBase64
        case unknownSessionKeyVersion(UInt8)
        case sessionKeyTooShort
        case invalidMessageVersion(UInt8)
        case messageTooShort
        case missingCiphertextField
        case messageIndexBeforeSessionStart(messageIndex: UInt32, sessionIndex: UInt32)
        case macVerificationFailed
        case aesFailed(CCCryptorStatus)
        case invalidPlaintext
    }

    // MARK: - Ratchet state

    private struct RatchetState {
        var r0: Data
        var r1: Data
        var r2: Data
        var r3: Data
        var index: UInt32
    }

    // MARK: - Entry point

    /// Decrypt a Megolm ciphertext using a session key from `m.room_key`.
    ///
    /// - Parameters:
    ///   - ciphertextBase64: The `ciphertext` field from the Matrix event
    ///     content (standard or url-safe base64).
    ///   - sessionKeyBase64url: The `session_key` field from the `m.room_key`
    ///     to-device event (url-safe base64, version 0x02).
    /// - Returns: The decrypted plaintext JSON string.
    static func decrypt(
        ciphertextBase64: String,
        sessionKeyBase64url: String
    ) throws -> String {
        var state = try parseSessionKey(sessionKeyBase64url)
        let msg = try parseMessage(ciphertextBase64)
        guard msg.messageIndex >= state.index else {
            throw DecryptionError.messageIndexBeforeSessionStart(
                messageIndex: msg.messageIndex,
                sessionIndex: state.index)
        }
        advanceRatchet(&state, to: msg.messageIndex)
        let keys = try deriveKeys(state)
        try verifyMAC(keys: keys, msg: msg)
        let plaintext = try aesDecrypt(
            ciphertext: msg.ciphertext,
            aesKey: keys.aesKey,
            aesIV: keys.aesIV)
        guard let string = String(data: plaintext, encoding: .utf8) else {
            throw DecryptionError.invalidPlaintext
        }
        return string
    }

    /// Extracts the `content` dictionary from the decrypted plaintext JSON.
    /// Callers use this to derive a user-friendly notification body (e.g. mapping msgtype).
    static func extractContent(from plaintextJSON: String) -> [String: Any]? {
        guard let data = plaintextJSON.data(using: .utf8),
              let outer = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return outer["content"] as? [String: Any]
    }

    // MARK: - Session key parsing

    private static func parseSessionKey(_ base64url: String) throws -> RatchetState {
        let bytes = try decodeBase64(base64url)
        guard !bytes.isEmpty else { throw DecryptionError.sessionKeyTooShort }
        let version = bytes[0]

        switch version {
        case 0x02:
            // vodozemac format: 0x02 | index(4 BE) | R0(32) | R1(32) | R2(32) | R3(32) | Kpub(32) | signature(64) = 229 bytes
            // Note: old libolm used 0x02 WITHOUT the index prefix (225 bytes), but vodozemac includes it.
            guard bytes.count >= 133 else { throw DecryptionError.sessionKeyTooShort }
            let idx = UInt32(bytes[1]) << 24
                | UInt32(bytes[2]) << 16
                | UInt32(bytes[3]) << 8
                | UInt32(bytes[4])
            return RatchetState(
                r0: Data(bytes[5..<37]),
                r1: Data(bytes[37..<69]),
                r2: Data(bytes[69..<101]),
                r3: Data(bytes[101..<133]),
                index: idx)
        case 0x01:
            // Format: 0x01 | index(4 BE) | R0(32)|R1(32)|R2(32)|R3(32) | Kpub(32) | MAC(32)
            guard bytes.count >= 165 else { throw DecryptionError.sessionKeyTooShort }
            let idx = UInt32(bytes[1]) << 24
                | UInt32(bytes[2]) << 16
                | UInt32(bytes[3]) << 8
                | UInt32(bytes[4])
            return RatchetState(
                r0: Data(bytes[5..<37]),
                r1: Data(bytes[37..<69]),
                r2: Data(bytes[69..<101]),
                r3: Data(bytes[101..<133]),
                index: idx)
        default:
            throw DecryptionError.unknownSessionKeyVersion(version)
        }
    }

    // MARK: - Message parsing

    private struct ParsedMessage {
        let messageIndex: UInt32
        let ciphertext: Data
        let allBeforeMAC: Data
        let mac: Data
    }

    private static func parseMessage(_ base64: String) throws -> ParsedMessage {
        let bytes = try decodeBase64(base64)
        guard bytes.count > 9 else { throw DecryptionError.messageTooShort }
        guard bytes[0] == 0x03 else { throw DecryptionError.invalidMessageVersion(bytes[0]) }

        // Log first bytes for debugging when decryption fails.
        let debugPrefix = bytes.prefix(8).map { String(format: "%02x", $0) }.joined(separator: " ")
        MXLog.info("MegolmDecryptor.parseMessage: bytes[\(bytes.count)] prefix: \(debugPrefix)")

        // vodozemac format: version(1) | protobuf(field1+field2) | mac(8) | ed25519_sig(64)
        // libolm format:    version(1) | protobuf(field1+field2) | mac(8)
        // Parse protobuf fields, tracking where they end so we can extract the MAC correctly.
        var pos = 1
        var messageIndex: UInt32 = 0
        var ciphertext: Data?
        var protoEnd = 1  // tracks end of the last successfully parsed protobuf field

        while pos < bytes.count {
            let savedPos = pos
            let tag = bytes[pos]; pos += 1
            let fieldNumber = tag >> 3
            let wireType = tag & 0x07

            if fieldNumber == 1, wireType == 0 {
                (messageIndex, pos) = try readVarint(bytes, at: pos)
                protoEnd = pos
            } else if fieldNumber == 2, wireType == 2 {
                var length: UInt32
                (length, pos) = try readVarint(bytes, at: pos)
                let end = pos + Int(length)
                guard end <= bytes.count else { throw DecryptionError.missingCiphertextField }
                ciphertext = Data(bytes[pos..<end])
                pos = end
                protoEnd = pos
            } else {
                // Hit MAC/signature bytes or an unknown field — stop protobuf parsing here.
                MXLog.info("MegolmDecryptor: stopped at unknown field \(fieldNumber) wireType \(wireType) at pos \(savedPos)")
                pos = savedPos
                break
            }
        }

        // MAC immediately follows the protobuf fields.
        guard protoEnd + 8 <= bytes.count else { throw DecryptionError.messageTooShort }
        let allBeforeMAC = Data(bytes[0..<protoEnd])
        let mac = Data(bytes[protoEnd..<(protoEnd + 8)])

        guard let ct = ciphertext else { throw DecryptionError.missingCiphertextField }
        return ParsedMessage(
            messageIndex: messageIndex,
            ciphertext: ct,
            allBeforeMAC: allBeforeMAC,
            mac: mac)
    }

    private static func readVarint(_ bytes: [UInt8], at start: Int) throws -> (UInt32, Int) {
        var result: UInt32 = 0
        var shift: UInt32 = 0
        var pos = start
        while pos < bytes.count {
            let byte = bytes[pos]; pos += 1
            result |= UInt32(byte & 0x7F) << shift
            if byte & 0x80 == 0 { break }
            shift += 7
        }
        return (result, pos)
    }

    // MARK: - Ratchet advancement

    /// Advances `state` from its current index to `targetIndex`.
    ///
    /// Megolm ratchet advancement rules (step i → i+1):
    /// - Always: advance R3 from itself.
    /// - When (i+1) % 256 == 0: advance R2, re-derive R3 from new R2.
    /// - When (i+1) % 65536 == 0: advance R1, re-derive R2 and R3.
    /// - When (i+1) % 16777216 == 0: advance R0, re-derive R1, R2, R3.
    /// Where "advance Rj" = HMAC-SHA256(key=Rj, msg=j) and
    /// "re-derive Rj from Rj-1" = HMAC-SHA256(key=Rj-1, msg=j).
    private static func advanceRatchet(_ state: inout RatchetState, to targetIndex: UInt32) {
        while state.index < targetIndex {
            let next = state.index + 1
            if next % 16_777_216 == 0 {
                state.r0 = hmac(key: state.r0, byte: 0x00)
                state.r1 = hmac(key: state.r0, byte: 0x01)
                state.r2 = hmac(key: state.r1, byte: 0x02)
                state.r3 = hmac(key: state.r2, byte: 0x03)
            } else if next % 65_536 == 0 {
                state.r1 = hmac(key: state.r1, byte: 0x01)
                state.r2 = hmac(key: state.r1, byte: 0x02)
                state.r3 = hmac(key: state.r2, byte: 0x03)
            } else if next % 256 == 0 {
                state.r2 = hmac(key: state.r2, byte: 0x02)
                state.r3 = hmac(key: state.r2, byte: 0x03)
            } else {
                state.r3 = hmac(key: state.r3, byte: 0x03)
            }
            state.index = next
        }
    }

    // MARK: - Key derivation

    private struct MegolmKeys {
        let aesKey: Data
        let macKey: Data
        let aesIV: Data
    }

    private static func deriveKeys(_ state: RatchetState) throws -> MegolmKeys {
        let ikm = state.r0 + state.r1 + state.r2 + state.r3
        let salt = Data(repeating: 0, count: SHA256.Digest.byteCount)
        let info = Data("MEGOLM_KEYS".utf8)

        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: ikm),
            salt: salt,
            info: info,
            outputByteCount: 80)
        let all = derived.withUnsafeBytes { Data($0) }
        return MegolmKeys(
            aesKey: all.subdata(in: 0..<32),
            macKey: all.subdata(in: 32..<64),
            aesIV: all.subdata(in: 64..<80))
    }

    // MARK: - MAC verification

    private static func verifyMAC(keys: MegolmKeys, msg: ParsedMessage) throws {
        let auth = HMAC<SHA256>.authenticationCode(
            for: msg.allBeforeMAC,
            using: SymmetricKey(data: keys.macKey))
        let computed = Data(auth.prefix(8))
        guard computed == msg.mac else {
            throw DecryptionError.macVerificationFailed
        }
    }

    // MARK: - AES-256-CBC decryption

    private static func aesDecrypt(ciphertext: Data, aesKey: Data, aesIV: Data) throws -> Data {
        var outBuf = [UInt8](repeating: 0, count: ciphertext.count + kCCBlockSizeAES128)
        var decrypted = 0

        let status = ciphertext.withUnsafeBytes { ctPtr in
            aesKey.withUnsafeBytes { keyPtr in
                aesIV.withUnsafeBytes { ivPtr in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyPtr.baseAddress, kCCKeySizeAES256,
                        ivPtr.baseAddress,
                        ctPtr.baseAddress, ciphertext.count,
                        &outBuf, outBuf.count,
                        &decrypted)
                }
            }
        }

        guard status == kCCSuccess else {
            throw DecryptionError.aesFailed(status)
        }
        return Data(outBuf.prefix(decrypted))
    }

    // MARK: - Helpers

    private static func hmac(key: Data, byte: UInt8) -> Data {
        Data(HMAC<SHA256>.authenticationCode(
            for: Data([byte]),
            using: SymmetricKey(data: key)))
    }

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
