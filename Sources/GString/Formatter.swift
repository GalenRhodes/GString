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

    public func format(_ parameters: Any...) -> String {
        var out: String      = ""
        var idx: StringIndex = startIndex
        var arg: Int         = 0

        while idx < endIndex {
            let ch = self[idx]
            formIndex(after: &idx)

            if ch == "%" {
                let formatData = FormatData(argumentIndex: &arg, string: self, index: &idx)
            }
            else {
                out.append(ch)
            }
        }

        return out
    }

    enum TimeSpec: Character {
        case HOUR024       = "H"
        case HOUR012       = "I"
        case HOUR24        = "k"
        case HOUR12        = "l"
        case MINUTE        = "M"
        case SECOND        = "S"
        case MILLIS        = "L"
        case NANOS         = "N"
        case AMPM          = "p"
        case TZ_NUM        = "z"
        case TZ_NAME       = "Z"
        case EPOCH_SECONDS = "s"
        case EPOCH_MILLIS  = "Q"
        case MONTH_LONG    = "B"
        case MONTH_SHORT   = "b"
        case DAY_LONG      = "A"
        case DAY_SHORT     = "a"
        case YEAR_LONG     = "Y"
        case YEAR_SHORT    = "y"
        case CENTURY       = "C"
        case DAY_OF_YEAR   = "j"
        case DATE0         = "d"
        case DATE          = "e"
        case R             = "R"
        case T             = "T"
        case r             = "r"
        case D             = "D"
        case F             = "F"
        case c             = "c"
    }

    enum ConversionSpec: String {
        case STRING  = "sS"
        case PERCENT = "%"
        case BOOL    = "bB"
        case HASH    = "hH"
        case CHAR    = "cC"
        case DECIMAL = "d"
        case OCTAL   = "o"
        case HEX     = "xX"
        case EXP     = "eE"
        case FLOAT   = "f"
        case F_EXP   = "gG"
        case TIME    = "tT"
    }

    enum FormatParseState {
        case ArgIndex, Flags, Width, Precision, Conversion, DateTime, Done
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
        var width:               UInt           = 0
        var precision:           UInt           = 0
        var argumentIndex:       Int            = 0
        var conversionSpecifier: ConversionSpec = .PERCENT

        init(argumentIndex: inout Int, string str: String, index idx: inout StringIndex) {
            self.argumentIndex = argumentIndex
            argumentIndex += 1
            var state: FormatParseState = .ArgIndex

            while state != .Done && idx < str.endIndex {
                var ch = str[idx]

                switch state {
                    case .ArgIndex:
                        if ch == "<" {
                            guard argumentIndex > 0 else { fatalError() }
                            next(string: str, index: &idx)
                            self.argumentIndex = argumentIndex - 1
                        }
                        else if ch >= "0" && ch <= "9" {
                            let value = parseNumber(string: str, index: &idx, character: &ch)

                            if ch == "$" {
                                next(string: str, index: &idx)
                                self.argumentIndex = value
                            }
                            else {
                                self.argumentIndex = argumentIndex
                                argumentIndex += 1

                                if value == 0 {
                                    zeroPadded = true
                                }
                                else {
                                    width = UInt(bitPattern: value)
                                    state = .Precision
                                    continue
                                }
                            }
                        }
                        state = .Flags

                    case .Flags:
                        repeat {
                            switch ch {
                                case "-":
                                    leftJustified = true
                                    ch = next(string: str, index: &idx)
                                case "#":
                                    alternateForm = true
                                    ch = next(string: str, index: &idx)
                                case "+":
                                    includeSign = true
                                    ch = next(string: str, index: &idx)
                                case " ":
                                    leadingSpace = true
                                    ch = next(string: str, index: &idx)
                                case "0":
                                    zeroPadded = true
                                    ch = next(string: str, index: &idx)
                                case ",":
                                    groupingSeparators = true
                                    ch = next(string: str, index: &idx)
                                case "(":
                                    negativeParentheses = true
                                    ch = next(string: str, index: &idx)
                                default:
                                    state = .Width
                            }
                        }
                        while state == .Flags

                    case .Width:
                        if ch >= "0" && ch <= "9" {
                            width = UInt(bitPattern: parseNumber(string: str, index: &idx, character: &ch))
                        }
                        state = .Precision

                    case .Precision:
                        if ch == "." {
                            ch = next(string: str, index: &idx)
                            guard ch >= "0" && ch <= "9" else { fatalError() }
                            precision = UInt(bitPattern: parseNumber(string: str, index: &idx, character: &ch))
                        }
                        state = .Conversion

                    case .Conversion:
                        upperCase = ch.isUppercase
                        switch ch {
                            case "t", "T":
                                conversionSpecifier = .TIME
                                state = .DateTime
                                next(string: str, index: &idx)
                                continue
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
                        state = .Done

                    case .DateTime:
                        <#code#>

                    case .Done:
                        break
                }
            }
        }

        @discardableResult private func next(string str: String, index idx: inout StringIndex) -> Character {
            str.formIndex(after: &idx)
            guard idx < str.endIndex else { fatalError() }
            return str[idx]
        }

        private func parseNumber(string str: String, index idx: inout StringIndex, character ch: inout Character) -> Int {
            var value = 0
            let zero  = toAscii(char: "0")

            while ch >= "0" && ch <= "9" {
                value = ((value * 10) + (toAscii(char: ch) - zero))
                ch = next(string: str, index: &idx)
            }

            return value
        }

        private func toAscii(char ch: Character) -> Int {
            Int(bitPattern: UInt(ch.asciiValue!))
        }
    }
}
