/*===============================================================================================================================================================================*
 *     PROJECT: GString
 *    FILENAME: RegularExpression.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: June 02, 2022
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

extension RegularExpression {

    /// Splits the given string around matches of the this regular expression.
    ///
    /// The array returned by this method contains each substring of the given string that is terminated by another substring that matches
    /// this expression or is terminated by the end of the string. The substrings in the array are in the order in which they
    /// occur in this string. If this expression does not match any part of the input then the resulting array has just one element,
    /// namely the given string.
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
    ///   - string: The string to split.
    ///   - limit:  The result threshold, as described above.
    /// - Returns: The array of strings computed by splitting the given string around matches of this regular expression.
    ///
    public func split(string: String, limit: Int = 0) -> [String] {
        guard limit != 1 else { return [ string ] }

        var idx: StringIndex = string.startIndex
        var arr: [String]    = []

        forEachMatch(in: string) { (match: RegularExpression.Match?, _, stop: inout Bool) in
            if let match = match, let range = match[0].range {
                if range.lowerBound == string.startIndex {
                    if !range.isEmpty { arr.append("") }
                }
                else {
                    arr.append(String(string[idx ..< range.lowerBound]))
                }

                idx = range.upperBound
                if limit > 1 && arr.count >= (limit - 1) {
                    arr.append(String(string[idx...]))
                    stop = true
                }
            }
        }

        let j = (arr.count - 1)
        guard j >= 0 else { return [ string ] }
        guard limit == 0 && arr.count > 1 else { return arr }

        for i in stride(from: j, to: 0, by: -1) {
            guard arr[i].isEmpty else {
                if i < j { arr.removeSubrange((i + 1)...) }
                return arr
            }
        }

        arr.removeSubrange(1...)
        return arr
    }
}
