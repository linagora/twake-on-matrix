//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation
import MatrixRustSDK
import UIKit

private final class MediaRequest {
    var continuations: [CheckedContinuation<Data, Error>] = []
}

private enum MediaRequestKey: Hashable {
    case content(MediaSourceProxy)
    case thumbnail(MediaSourceProxy, width: UInt, height: UInt)
}

actor MediaLoader: MediaLoaderProtocol {
    private let client: ClientProtocol
    private let clientQueue: DispatchQueue
    private var ongoingRequests = [MediaRequestKey: MediaRequest]()

    init(client: ClientProtocol,
         clientQueue: DispatchQueue = .global()) {
        self.client = client
        self.clientQueue = clientQueue
    }
    
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await enqueueLoadMediaRequest(forKey: .content(source)) {
            try await self.client.getMediaContent(mediaSource: source.underlyingSource)
        }
    }
    
    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await enqueueLoadMediaRequest(forKey: .thumbnail(source, width: width, height: height)) {
            try await self.client.getMediaThumbnail(mediaSource: source.underlyingSource, width: UInt64(width), height: UInt64(height))
        }
    }
    
    func loadMediaFileForSource(_ source: MediaSourceProxy, body filename: String?) async throws -> MediaFileHandleProxy {
        let result = try await self.client.getMediaFile(mediaSource: source.underlyingSource, filename: filename, mimeType: source.mimeType ?? "application/octet-stream", useCache: true, tempDir: nil)
        
        return MediaFileHandleProxy(handle: result)
    }
    
    // MARK: - Private
    
    private func enqueueLoadMediaRequest(forKey key: MediaRequestKey, operation: @escaping () async throws -> Data) async throws -> Data {
        if let ongoingRequest = ongoingRequests[key] {
            return try await withCheckedThrowingContinuation { continuation in
                ongoingRequest.continuations.append(continuation)
            }
        }
        
        let ongoingRequest = MediaRequest()
        ongoingRequests[key] = ongoingRequest
        
        defer {
            ongoingRequests[key] = nil
        }
        
        do {
            let result = try await operation()
            
            ongoingRequest.continuations.forEach { $0.resume(returning: result) }
            
            return result
            
        } catch {
            ongoingRequest.continuations.forEach { $0.resume(throwing: error) }
            throw error
        }
    }
}
