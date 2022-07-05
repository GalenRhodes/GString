/*===============================================================================================================================================================================*
 *     PROJECT: GString
 *    FILENAME: Formatter.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: June 28, 2022
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

extension String {

    public func format(_ parameters: Any?...) -> String {
        var out: String      = ""
        var idx: StringIndex = startIndex
        var arg: Int         = 0

        while idx < endIndex {
            let ch = self[idx]
            formIndex(after: &idx)

            if ch == "%" {
                let formatData   = FormatData(argumentIndex: &arg, string: self, index: &idx)
                var work: String = ""

                switch formatData.conversionSpecifier {
                    case .STRING:
                        work = "\(parameters[formatData.argumentIndex] ?? "nil")"
                        fmtWidthCase(formatData: formatData, work: &work, out: &out)

                    case .PERCENT:
                        work = "%"

                    case .BOOL:
                        let _bool = parameters[formatData.argumentIndex]
                        if _bool == nil { work = "nil" }
                        else if let bool = _bool as? Bool { work = bool ? "true" : "false" }
                        else { fatalError() }
                        fmtWidthCase(formatData: formatData, work: &work, out: &out)

                    case .HASH:
                        break

                    case .CHAR:
                        var c: Character? = parameters[formatData.argumentIndex] as? Character

                        if c == nil {
                            let str = "\(parameters[formatData.argumentIndex] ?? " ")"
                            if str.count < 1 { c = " " }
                            else { c = str[str.startIndex] }
                        }

                        work.append(c ?? " ")
                        fmtWidthCase(formatData: formatData, work: &work, out: &out)

                    case .DECIMAL:
                        if let i = getInteger(parameters[formatData.argumentIndex]) {
                            let f = NumberFormatter()
                            f.numberStyle = .decimal
                            f.minimumFractionDigits = 0
                            f.maximumFractionDigits = 0
                            f.minimumIntegerDigits = 1
                            f.formatWidth = formatData.width
                            if formatData.groupingSeparators {
                                f.groupingSize = 3
                                f.groupingSeparator = ","
                                f.hasThousandSeparators = true
                            }
                        }
                        else {
                            work = "nil"
                        }
                        fmtWidthCase(formatData: formatData, work: &work, out: &out)

                    case .OCTAL:
                        break

                    case .HEX:
                        break

                    case .EXP:
                        break

                    case .FLOAT:
                        break

                    case .F_EXP:
                        break

                    case .TIME:
                        break
                }
                out.append(work)
            }
            else {
                out.append(ch)
            }
        }

        return out
    }

    private func getInteger(_ param: Any?) -> Int? {
        guard let param = param else { return nil }

        if let i = param as? Int { return i }
        if let i = param as? Int64 { return Int(truncatingIfNeeded: i) }
        if let i = param as? Int32 { return Int(i) }
        if let i = param as? Int16 { return Int(i) }
        if let i = param as? Int8 { return Int(i) }
        if let i = param as? UInt { return Int(bitPattern: i) }
        if let i = param as? UInt64 { return Int(bitPattern: UInt(truncatingIfNeeded: i)) }
        if let i = param as? UInt32 { return Int(bitPattern: UInt(i)) }
        if let i = param as? UInt16 { return Int(bitPattern: UInt(i)) }
        if let i = param as? UInt8 { return Int(bitPattern: UInt(i)) }

        if let d = param as? Double { return Int(d) }
        if let f = param as? Float { return Int(f) }
        fatalError()
    }

    private func getDouble(_ param: Any?) -> Double? {
        guard let param = param else { return nil }

        if let d = param as? Double { return d }
        if let f = param as? Float { return Double(f) }

        if let i = param as? Int { return Double(i) }
        if let i = param as? Int64 { return Double(i) }
        if let i = param as? Int32 { return Double(i) }
        if let i = param as? Int16 { return Double(i) }
        if let i = param as? Int8 { return Double(i) }
        if let i = param as? UInt { return Double(i) }
        if let i = param as? UInt64 { return Double(i) }
        if let i = param as? UInt32 { return Double(i) }
        if let i = param as? UInt16 { return Double(i) }
        if let i = param as? UInt8 { return Double(i) }
        fatalError()
    }

    private func fmtWidthCase(formatData: FormatData, work: inout String, out: inout String) {
        if formatData.upperCase { work = work.uppercased() }
        if formatData.width > work.count {
            for _ in (work.count ..< formatData.width) {
                if formatData.leftJustified { out.append(" ") }
                else { out.insert(" ", at: out.startIndex) }
            }
        }
    }

    enum FormatParseState {
        case Begin, ArgIndex, Flags, Width, Precision, Conversion, Done
    }

    enum ConversionSpec {
        case STRING, PERCENT, BOOL, HASH, CHAR, DECIMAL, OCTAL, HEX, EXP, FLOAT, F_EXP, TIME
    }

    enum TimeSpec {
        case HOUR024, HOUR012, HOUR24, HOUR12, MINUTE, SECOND, MILLIS, NANOS, AMPM, TZ_NUM, TZ_NAME, EPOCH_SECONDS, EPOCH_MILLIS, MONTH_LONG, MONTH_SHORT, DAY_LONG, DAY_SHORT, YEAR_LONG, YEAR_SHORT,
             CENTURY, DAY_OF_YEAR, DATE0, DATE, R, T, r, D, F, c
    }

    class FormatData {
        var leftJustified:       Bool           = false
        var alternateForm:       Bool           = false
        var includeSign:         Bool           = false
        var leadingSpace:        Bool           = false
        var zeroPadded:          Bool           = false
        var groupingSeparators:  Bool           = false
        var negativeParentheses: Bool           = false
        var upperCase:           Bool           = false
        var width:               Int            = 0
        var precision:           Int            = 0
        var argumentIndex:       Int            = 0
        var conversionSpecifier: ConversionSpec = .PERCENT
        var timeSpecifier:       TimeSpec?      = nil

        init(argumentIndex: inout Int, string str: String, index idx: inout StringIndex) {
            guard idx < str.endIndex else { fatalError() }

            if str[idx] == "%" {
                conversionSpecifier = .PERCENT
                str.formIndex(after: &idx)
            }
            else {
                var state: FormatParseState = .ArgIndex
                var prev:  FormatParseState = .Begin

                repeat {
                    switch state {
                        case .Begin:      (prev, state) = (.Begin, .ArgIndex)
                        case .ArgIndex:   (prev, state) = parseArgIndex(string: str, index: &idx, argumentIndex: &argumentIndex)
                        case .Flags:      (prev, state) = parseFlags(string: str, index: &idx)
                        case .Width:      (prev, state) = parseWidth(string: str, index: &idx, prevState: prev)
                        case .Precision:  (prev, state) = parsePrecision(string: str, index: &idx, prevState: prev)
                        case .Conversion: (prev, state) = parseConversion(string: str, index: &idx)
                        case .Done:       break
                    }
                }
                while state != .Done
            }
        }

        private func parseArgIndex(string str: String, index idx: inout StringIndex, argumentIndex argIdx: inout Int) -> (FormatParseState, FormatParseState) {
            switch str[idx] {
                case "<":
                    guard argIdx > 0 else { fatalError() }
                    argumentIndex = argIdx - 1
                    next(string: str, index: &idx)
                case "0":
                    break
                case "1" ... "9":
                    let value = parseNumber(string: str, index: &idx)!
                    if str[idx] == "$" {
                        argumentIndex = value
                        next(string: str, index: &idx)
                    }
                    else {
                        width = value
                        return (.Width, .Precision)
                    }
                default:
                    argumentIndex = argIdx
                    argIdx += 1
            }
            return (.ArgIndex, .Flags)
        }

        private func parseFlags(string str: String, index idx: inout StringIndex) -> (FormatParseState, FormatParseState) {
            repeat {
                switch str[idx] {
                    case "-": leftJustified = true
                    case "#": alternateForm = true
                    case "+": includeSign = true
                    case " ": leadingSpace = true
                    case "0": zeroPadded = true
                    case ",": groupingSeparators = true
                    case "(": negativeParentheses = true
                    default:  return (.Flags, .Width)
                }
                next(string: str, index: &idx)
            }
            while true
        }

        private func parseWidth(string str: String, index idx: inout StringIndex, prevState prev: FormatParseState) -> (FormatParseState, FormatParseState) {
            if let value = parseNumber(string: str, index: &idx) {
                width = value
                return (.Width, .Precision)
            }
            return (prev, .Conversion)
        }

        private func parsePrecision(string str: String, index idx: inout StringIndex, prevState prev: FormatParseState) -> (FormatParseState, FormatParseState) {
            if str[idx] == "." {
                next(string: str, index: &idx)
                guard let value = parseNumber(string: str, index: &idx) else { fatalError() }
                precision = value
                return (.Precision, .Conversion)
            }
            return (prev, .Conversion)
        }

        private func parseConversion(string str: String, index idx: inout StringIndex) -> (FormatParseState, FormatParseState) {
            let ch = str[idx]
            upperCase = ch.isUppercase
            switch ch {
                case "t", "T": parseTimeSpec(string: str, index: &idx)
                case "s", "S": conversionSpecifier = .STRING
                case "b", "B": conversionSpecifier = .BOOL
                case "h", "H": conversionSpecifier = .HASH
                case "c", "C": conversionSpecifier = .CHAR
                case "x", "X": conversionSpecifier = .HEX
                case "e", "E": conversionSpecifier = .EXP
                case "g", "G": conversionSpecifier = .F_EXP
                case "%":      conversionSpecifier = .PERCENT
                case "d":      conversionSpecifier = .DECIMAL
                case "o":      conversionSpecifier = .OCTAL
                case "f":      conversionSpecifier = .FLOAT
                default: fatalError()
            }
            str.formIndex(after: &idx)
            return (.Conversion, .Done)
        }

        private func parseTimeSpec(string str: String, index idx: inout StringIndex) {
            conversionSpecifier = .TIME
            next(string: str, index: &idx)
            switch str[idx] {
                case "H": timeSpecifier = .HOUR024
                case "I": timeSpecifier = .HOUR012
                case "k": timeSpecifier = .HOUR24
                case "l": timeSpecifier = .HOUR12
                case "M": timeSpecifier = .MINUTE
                case "S": timeSpecifier = .SECOND
                case "L": timeSpecifier = .MILLIS
                case "N": timeSpecifier = .NANOS
                case "p": timeSpecifier = .AMPM
                case "z": timeSpecifier = .TZ_NUM
                case "Z": timeSpecifier = .TZ_NAME
                case "s": timeSpecifier = .EPOCH_SECONDS
                case "Q": timeSpecifier = .EPOCH_MILLIS
                case "B": timeSpecifier = .MONTH_LONG
                case "b": timeSpecifier = .MONTH_SHORT
                case "A": timeSpecifier = .DAY_LONG
                case "a": timeSpecifier = .DAY_SHORT
                case "Y": timeSpecifier = .YEAR_LONG
                case "y": timeSpecifier = .YEAR_SHORT
                case "C": timeSpecifier = .CENTURY
                case "j": timeSpecifier = .DAY_OF_YEAR
                case "d": timeSpecifier = .DATE0
                case "e": timeSpecifier = .DATE
                case "R": timeSpecifier = .R
                case "T": timeSpecifier = .T
                case "r": timeSpecifier = .r
                case "D": timeSpecifier = .D
                case "F": timeSpecifier = .F
                case "c": timeSpecifier = .c
                default: fatalError()
            }
        }

        private func parseNumber(string str: String, index idx: inout StringIndex) -> Int? {
            var value: Int? = nil
            while let asc = str[idx].asciiValue, asc >= 48 && asc <= 57 {
                value = (((value ?? 0) * 10) + (Int(asc) - 48))
                next(string: str, index: &idx)
            }
            return value
        }

        private func next(string str: String, index idx: inout StringIndex) {
            guard idx < str.endIndex else { fatalError() }
            str.formIndex(after: &idx)
            guard idx < str.endIndex else { fatalError() }
        }
    }
}

