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

/// Extensions to the string structure.
/// 
extension String {

    public var trimmed:   String { trimmingCharacters(in: .whitespacesAndNewlines.union(.controlCharacters)) }
    public var fullRange: StringRange { startIndex ..< endIndex }

    /// Splits this string around matches of the given regular expression.
    /// The array returned by this method contains each substring of this string that is terminated by another substring that matches
    /// the given expression or is terminated by the end of the string. The substrings in the array are in the order in which they
    /// occur in this string. If the expression does not match any part of the input then the resulting array has just one element,
    /// namely this string.
    ///
    /// When there is a positive-width match at the beginning of this string then an empty leading substring is included at the
    /// beginning of the resulting array. A zero-width match at the beginning however never produces such empty leading substring.
    ///
    /// The limit parameter controls the number of times the pattern is applied and therefore affects the length of the resulting
    /// array. If the limit n is greater than zero then the pattern will be applied at most n - 1 times, the array's length will
    /// be no greater than n, and the array's last entry will contain all input beyond the last matched delimiter. If n is non-positive
    /// then the pattern will be applied as many times as possible and the array can have any length. If n is zero then the
    /// pattern will be applied as many times as possible, the array can have any length, and trailing empty strings will be discarded.
    ///
    /// The string "boo:and:foo", for example, yields the following results with these parameters:
    ///
    /// | Regex | Limit | Result                        |
    /// |:-----:|:-----:|:------------------------------|
    /// |   :   |   2   | { "boo", "and:foo" }          |
    /// |   :   |   5   | { "boo", "and", "foo" }       |
    /// |   :   |  -2   | { "boo", "and", "foo" }       |
    /// |   o   |   5   | { "b", "", ":and:f", "", "" } |
    /// |   o   |  -2   | { "b", "", ":and:f", "", "" } |
    /// |   o   |   0   | { "b", "", ":and:f" }         |
    ///
    /// - Parameters:
    ///   - pattern:
    ///   - limit:
    ///   - error:
    /// - Returns:
    ///
    public func split(pattern: String, limit: Int = 0, error: inout Error?) -> [String] {
        guard let rx = RegularExpression(pattern: pattern, error: &error) else { return [ self ] }
        guard limit != 1 else { return [ self ] }

        var idx: StringIndex = startIndex
        var arr: [String]    = []

        rx.forEachMatch(in: self) { (match: RegularExpression.Match?, _, stop: inout Bool) in
            if let match = match, let range = match[0].range {
                if range.lowerBound == startIndex { if !range.isEmpty { arr.append("") } }
                else { arr.append(String(self[idx ..< range.lowerBound])) }

                idx = range.upperBound
                if limit > 1 && arr.count >= (limit - 1) {
                    arr.append(String(self[idx...]))
                    stop = true
                }
            }
        }

        guard arr.count > 0 else { return [ self ] }
        guard limit == 0 && arr.count > 1 else { return arr }
        let j = (arr.count - 1)

        for i in stride(from: j, to: 0, by: -1) {
            guard arr[i].isEmpty else {
                if i < j { arr.removeSubrange((i + 1)...) }
                return arr
            }
        }

        arr.removeSubrange(1...)
        return arr
    }

    public func split(pattern: String, limit: Int = 0) -> [String] {
        var error: Error? = nil
        return split(pattern: pattern, limit: limit, error: &error)
    }
}
