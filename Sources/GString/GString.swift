/*===============================================================================================================================================================================*
 *     PROJECT: GString
 *    FILENAME: GString.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: May 30, 2022
 *
 * Copyright © 2022. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation
import RegularExpression

public typealias StringIndex = String.Index
public typealias StringRange = Range<StringIndex>

extension String {

    public var trimmed:   String { trimmingCharacters(in: .whitespacesAndNewlines.union(.controlCharacters)) }
    public var fullRange: StringRange { startIndex ..< endIndex }

    public func split(pattern: String, limit: Int = 0, error: inout Error?) -> [String] {
        guard let rx = RegularExpression(pattern: pattern, error: &error) else { return [ self ] }
        var idx: StringIndex = startIndex
        rx.forEachMatch(in: self) { (match: RegularExpression.Match?, _, stop: inout Bool) in
            if let match = match {
                match.
            }
        }
        return [ self ]
    }

    public func split(pattern: String, limit: Int = 0) -> [String] {
        var error: Error? = nil
        return split(pattern: pattern, limit: limit, error: &error)
    }
}
