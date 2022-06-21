//
//  main.swift
//  DocFixer
//
//  Created by Galen Rhodes on 3/26/20.
//  Copyright © 2020 Project Galen. All rights reserved.
//

import Foundation
import RegularExpression

class DocFixer {
    lazy var p01:                String            = "[ \\t]"                    // Single space or tab
    lazy var p02:                String            = "(\\r\\n?|\\n)"             // Single line terminator
    lazy var p03:                String            = "^(?:\(p01)*///)"           // Doc comment block prefix
    lazy var p04:                String            = "((?:\(p03)(?:.*)\(p02))+)" // Doc comment block
    lazy var p05:                String            = "(\(p03))\(p01)?"           // Line comment prefix followed by an optional single space
    lazy var p06:                String            = "(?:\(p02)\(p02)+)"         // Two or more empty lines
    lazy var p07:                String            = "^(\\|.+?\\|\(p02))+"
    lazy var p08:                String            = "(?sm)^```.+?^```(\\r\\n?|\\n)"
    lazy var p09:                String            = "^\(p01)*\\-"
    lazy var rxDocCommentBlock:  RegularExpression = RegularExpression(pattern: p04, options: .anchorsMatchLines)!
    lazy var rxDocCommentPrefix: RegularExpression = RegularExpression(pattern: p05, options: .anchorsMatchLines)!
    lazy var rxLineTerminator:   RegularExpression = RegularExpression(pattern: p02, options: .anchorsMatchLines)!
    lazy var rxBlankLines:       RegularExpression = RegularExpression(pattern: p06, options: .anchorsMatchLines)!
    lazy var rxTableBlock:       RegularExpression = RegularExpression(pattern: p07)!
    lazy var rxCodeBlock:        RegularExpression = RegularExpression(pattern: p08, options: [ .anchorsMatchLines, .dotMatchesLineSeparators ])!
    lazy var fm:                 FileManager       = FileManager.default

    let BAR:            String = "-------------------------------------------------------------------------------------------------------------"
    let configFilename: String = "DocFixerConfig.json"
    let config:         DFConfig

    init() throws {
        config = try DFConfig.loadConfig(configFilename: configFilename)
        print("p01: \(p01)")
        print("p02: \(p02)")
        print("p03: \(p03)")
        print("p04: \(p04)")
        print("p05: \(p05)")
        print("p06: \(p06)")
        print("p07: \(p07)")
        print("p08: \(p08)")
        print("p09: \(p09)")
    }

    func documentationFixer() -> Int32 {
        for _p in config.paths {
            let path = _p.normalizedFilename

            print(BAR)
            print("    Path: \(path)")

            if let e: FileManager.DirectoryEnumerator = fm.enumerator(atPath: path) {
                while let filename = e.nextObject() as? String {
                    if filename.hasSuffix(".swift") && !filename.hasPrefix(".") {
                        let swiftFilename = filename.normalizedFilename(inPath: path)

                        print(BAR)
                        print("Filename: \(swiftFilename)")
                        print(BAR)

                        if let file = try? String(contentsOfFile: swiftFilename, encoding: .utf8) {
                            let output = rxDocCommentBlock.withMatchesReplaced(string: file) { match in
                                let paras: [String] = getParagraphs(removeDocBlockPrefix(rxDocCommentPrefix, match.subString.trimmed), rxLineTerminator)
                                var out:   String   = ""

                                for p in paras {
                                    if p.trimmed.hasAnyPrefix("|", "```") {
                                        out = ((out == "") ? p : (out + "\n\(p)"))
                                    }
                                    else {
                                        out = ((out == "") ? p.wrapTo(lineWidth: config.lineWidth, tabs: 4) : ("\(out)\n\(p.wrapTo(lineWidth: config.lineWidth, tabs: 4))"))
                                    }
                                }

                                return out
                            }
                        }
                        else {
                            print("   ERROR: Could not read file - \"(\(swiftFilename)\"")
                        }
                    }
                }
            }
        }

        print(BAR)
        return 0
    }

    private func getParagraphs(_ docBlock: String, _ rxLineTerminator: RegularExpression) -> [String] {
        let lines                = rxLineTerminator.split(string: docBlock)
        let y                    = lines.count
        var x                    = 0
        var paragraphs: [String] = []
        var para                 = ""

        while x < y {
            let line        = lines[x]
            let lineTrimmed = line.trimmed

            x += 1

            if lineTrimmed.isEmpty {
                addParagraph(&paragraphs, &para)
                while x < y && lines[x].trimmed.isEmpty { x += 1 }
            }
            else if lineTrimmed.hasPrefix("```") {
                addParagraph(&paragraphs, &para)
                para = lineTrimmed
                while x < y {
                    let l = lines[x]
                    guard l.trimmed != "```" else { break }
                    para += "\n\(l)"
                    x += 1
                }
                para += "\n```"
                addParagraph(&paragraphs, &para)
            }
            else if lineTrimmed.hasPrefix("|") {
                addParagraph(&paragraphs, &para)
                para = lineTrimmed
                while x < y {
                    let l = lines[x].trimmed
                    guard l.hasPrefix("|") else { break }
                    para += "\n\(l)"
                    x += 1
                }
                addParagraph(&paragraphs, &para)
            }
            else if lineTrimmed.hasPrefix("-") {
                addParagraph(&paragraphs, &para)
                para = line
                while x < y {
                    let l = lines[x].trimmed
                    guard !l.hasPrefix("-") else { break }
                    para += " \(l)"
                    x += 1
                }
                addParagraph(&paragraphs, &para)
            }
            else {
                para += " \(lineTrimmed)"
            }
        }

        addParagraph(&paragraphs, &para)
        return paragraphs
    }

    private func addParagraph(_ paragraphs: inout [String], _ para: inout String) {
        if !para.isEmpty {
            paragraphs.append(para)
            para = ""
        }
    }

    private func removeDocBlockPrefix(_ rxDocCommentPrefix: RegularExpression, _ str: String) -> String {
        rxDocCommentPrefix.withMatchesReplaced(string: str) { _ in "" }
    }

    enum DocFixerError: Error {
        case ConfigFileError(description: String)
        case RegexError(description: String)
    }
}

DispatchQueue.main.async {
    do {
        exit(try DocFixer().documentationFixer())
    }
    catch let e {
        print("ERROR: \(e.localizedDescription)")
        exit(1)
    }
}
dispatchMain()

