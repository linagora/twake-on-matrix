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

import Foundation

class NSELogger {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.alwaysShowsDecimalSeparator = true
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ""
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static var formattedMemoryAvailable: String {
        let freeBytes = os_proc_available_memory()
        let freeMB = Double(freeBytes) / 1024 / 1024
        guard let str = numberFormatter.string(from: NSNumber(value: freeMB)) else { return "" }
        return "\(str) MB"
    }

    private static var memoryFootprint: Float? {
        let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        guard let offset = MemoryLayout.offset(of: \task_vm_info_data_t.min_address) else { return nil }
        let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(offset / MemoryLayout<integer_t>.size)
        var info = task_vm_info_data_t()
        var count = TASK_VM_INFO_COUNT
        let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }
        guard kr == KERN_SUCCESS, count >= TASK_VM_INFO_REV1_COUNT else { return nil }
        return Float(info.phys_footprint)
    }

    public static var formattedMemoryFootprint: String {
        let usedBytes = UInt64(memoryFootprint ?? 0)
        let usedMB = Double(usedBytes) / 1024 / 1024
        guard let str = numberFormatter.string(from: NSNumber(value: usedMB)) else { return "" }
        return "\(str) MB"
    }

    static func configure() {}

    static func logMemory(with tag: String) {
        MXLog.info("\(tag) Memory: footprint: \(formattedMemoryFootprint) - available: \(formattedMemoryAvailable)")
    }
}
