//
//  main.swift
//  DocFixer
//
//  Created by Galen Rhodes on 3/26/20.
//  Copyright © 2020 Project Galen. All rights reserved.
//

import Foundation
import RegularExpression

let BAR: String = "-------------------------------------------------------------------------------------------------------------"

private func foo1(docBlock: String, rxLineTerminator: RegularExpression) -> [String] {
    let lines                = rxLineTerminator.split(string: docBlock)
    let y                    = lines.count
    var x                    = y
    var paragraphs: [String] = []

    while x < y {
        let line = lines[x]
        var para = ""
        x += 1

        if line.trimmed.isEmpty {
            if !para.isEmpty {
                paragraphs.append(para)
                para = ""
            }
            while x < y && lines[x].trimmed.isEmpty { x += 1 }
        }
        else if line.trimmed.hasPrefix("```") {
            if !para.isEmpty { paragraphs.append(para) }
            para = line.trimmed
            while x < y && lines[x].trimmed != "```" {
                para += "\n\(lines[x])"
                x += 1
            }
            paragraphs.append("\(para)\n```")
            para = ""
            if x < y { x += 1 }
        }
        else if line.trimmed.hasPrefix("|") {
            if !para.isEmpty { paragraphs.append(line) }
            para = line
            while x < y && lines[x].trimmed.hasPrefix("|") {
                para += "\n\(lines[x])"
                x += 1
            }
            paragraphs.append(para)
            para = ""
        }
        else {
            para += " \(line.trimmed)"
        }
    }

    return paragraphs
}

func documentationFixer() -> Int32 {
    do {
        let p01:                String            = "[ \\t]"                    // Single space or tab
        let p02:                String            = "(\\r\\n?|\\n)"             // Single line terminator
        let p03:                String            = "^(?:\(p01)*///)"           // Doc comment block prefix
        let p04:                String            = "((?:\(p03)(?:.*)\(p02))+)" // Doc comment block
        let p05:                String            = "(\(p03))\(p01)?"           // Line comment prefix followed by an optional single space
        let p06:                String            = "(?:\(p02)\(p02)+)"         // Two or more empty lines
        let p07:                String            = "^(\\|.+?\\|\(p02))+"
        let p08:                String            = "(?sm)^```.+?^```(\\r\\n?|\\n)"
        let p09:                String            = "^\(p01)*\\-"
        let configFilename:     String            = "DocFixerConfig.json"
        let rxDocCommentBlock:  RegularExpression = RegularExpression(pattern: p04, options: .anchorsMatchLines)!
        let rxDocCommentPrefix: RegularExpression = RegularExpression(pattern: p05, options: .anchorsMatchLines)!
        let rxLineTerminator:   RegularExpression = RegularExpression(pattern: p02, options: .anchorsMatchLines)!
        let rxBlankLines:       RegularExpression = RegularExpression(pattern: p06, options: .anchorsMatchLines)!
        let rxTableBlock:       RegularExpression = RegularExpression(pattern: p07)!
        let rxCodeBlock:        RegularExpression = RegularExpression(pattern: p08, options: [ .anchorsMatchLines, .dotMatchesLineSeparators ])!
        let fm:                 FileManager       = FileManager.default
        let config:             DFConfig          = try DFConfig.loadConfig(configFilename: configFilename)

        print("p01: \(p01)")
        print("p02: \(p02)")
        print("p03: \(p03)")
        print("p04: \(p04)")
        print("p05: \(p05)")
        print("p06: \(p06)")
        print("p07: \(p07)")
        print("p08: \(p08)")
        print("p09: \(p09)")

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
                                let docBlock = rxDocCommentPrefix.withMatchesReplaced(string: match.subString.trimmed) { _ in "" }
                                let paragraphs: [String] = foo1(docBlock: docBlock, rxLineTerminator: rxLineTerminator)

                                for para in paragraphs {
                                    print(para)
                                    print("---")
                                }

                                print("<--->")
                                return match.subString
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
    catch let e {
        print("ERROR: \(e.localizedDescription)")
        return 1
    }
}

enum DocFixerError: Error {
    case ConfigFileError(description: String)
    case RegexError(description: String)
}

DispatchQueue.main.async { exit(documentationFixer()) }
dispatchMain()

