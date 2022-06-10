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

    /// Shorthand for `trimmingCharacters(in: .whitespacesAndNewlines.union(.controlCharacters))`.
    public var trimmed:                   String { trimmingCharacters(in: .whitespacesAndNewlinesAndControlCharacters) }

    /// Shorthand for `startIndex ..< endIndex`.
    public var fullRange:                 StringRange { startIndex ..< endIndex }

    /// Replicates expandingTildeInPath found in NSString.
    public var expandingTildeInPath:      String { ((self as NSString).expandingTildeInPath as String) }

    /// If this string represents a file URL (begins with "file://" then it removes that prefix.
    public var urlAsFilename:             String { hasPrefix("file://") ? String(self[index(startIndex, offsetBy: "file://".count) ..< endIndex]) : self }

    /// Returns a string with any terminating forward slash (/) removed.
    public var removingLastPathSeparator: String { hasSuffix("/") ? String(self[startIndex ..< index(before: endIndex)]) : self }

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
    /// If there is a syntax error in the regular expression then this method will return an array whose only element is this string
    /// itself and the error will be returned in the inout parameter `error`.
    ///
    /// - Parameters:
    ///   - regex: The delimiting regular expression.
    ///   - limit:   The result threshold, as described above.
    ///   - error:   A reference to a field of type `Error` that will receive errors about the format of the `pattern`.
    /// - Returns: The array of strings computed by splitting this string around matches of the given regular expression.
    ///
    public func split(regex: String, limit: Int = 0, error: inout Error?) -> [String] {
        error = nil
        guard let rx = RegularExpression(pattern: regex, error: &error) else { return [ self ] }
        return rx.split(string: self, limit: limit)
    }

    /// Splits this string around matches of the given regular expression.
    /// This method functions exactly like the one above except that no error about the syntax of the pattern is returned if there is one.
    ///
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
    ///   - regex: The delimiting regular expression.
    ///   - limit: The result threshold, as described above.
    /// - Returns: The array of strings computed by splitting this string around matches of the given regular expression.
    ///
    public func split(regex: String, limit: Int = 0) -> [String] {
        var error: Error? = nil
        return split(regex: regex, limit: limit, error: &error)
    }
}
