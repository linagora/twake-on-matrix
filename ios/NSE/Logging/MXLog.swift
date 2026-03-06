//
// Copyright 2021 The Matrix.org Foundation C.I.C
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

import Foundation
import os

enum MXLog {
    private static let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "matrix", category: "NSE")

    static func verbose(_ message: Any, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, context: Any? = nil) {
        emit(.debug, message, file: file, line: line)
    }

    static func debug(_ message: Any, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, context: Any? = nil) {
        emit(.debug, message, file: file, line: line)
    }

    static func info(_ message: Any, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, context: Any? = nil) {
        emit(.default, message, file: file, line: line)
    }

    static func warning(_ message: Any, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, context: Any? = nil) {
        emit(.default, message, file: file, line: line)
    }

    static func error(_ message: Any, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, context: Any? = nil) {
        emit(.fault, message, file: file, line: line)
    }

    static func failure(_ message: Any, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column, context: Any? = nil) {
        emit(.fault, message, file: file, line: line)
        #if DEBUG
        assertionFailure("\(message)")
        #endif
    }

    private static func emit(_ type: OSLogType, _ message: Any, file: String, line: Int) {
        let msg = "[\((file as NSString).lastPathComponent):\(line)] \(message)"
        os_log("%{public}@", log: log, type: type, msg)
    }
}
