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

func documentationFixer() -> Int32 {
    do {
        let p01              = #"((?:^(?:[ \t]+///)(?:.*)(?:\r\n?|\n))+)"#
        let p02              = #"^[ \t]*/// ?"#
        let p03              = #"(\r\n?|\n)"#
        let p04              = p03 + p03
        let fm:  FileManager = FileManager.default
        var err: Error?      = nil
        let jd:  JSONDecoder = JSONDecoder()

        jd.allowsJSON5 = true

        let data:   Data     = try String(contentsOfFile: "DocFixerConfig.json", encoding: .utf8).data(using: .utf8)!
        let config: DFConfig = try jd.decode(DFConfig.self, from: data)

        guard let rx1 = RegularExpression(pattern: p01, options: .anchorsMatchLines, error: &err) else { throw DocFixerError.RegexError(description: err?.localizedDescription ?? "Bad REGEX.") }
        guard let rx2 = RegularExpression(pattern: p02, options: .anchorsMatchLines, error: &err) else { throw DocFixerError.RegexError(description: err?.localizedDescription ?? "Bad REGEX.") }
        guard let rx3 = RegularExpression(pattern: p03, options: .anchorsMatchLines, error: &err) else { throw DocFixerError.RegexError(description: err?.localizedDescription ?? "Bad REGEX.") }
        guard let rx4 = RegularExpression(pattern: p04, options: .anchorsMatchLines, error: &err) else { throw DocFixerError.RegexError(description: err?.localizedDescription ?? "Bad REGEX.") }

        for _path in config.paths {
            var path = _path.expandingTildeInPath.removingLastPathSeparator.urlAsFilename

            if path.hasPrefix("./") { path = "\(fm.currentDirectoryPath)\(path[path.index(after: path.startIndex)...])" }
            else if !path.hasPrefix("/") { path = "\(fm.currentDirectoryPath)/\(path)" }

            print(BAR)
            print("    Path: \(path)")
            print(BAR)

            if let e: FileManager.DirectoryEnumerator = fm.enumerator(atPath: path) {
                while let filename = e.nextObject() as? String {
                    if filename.hasSuffix(".swift") && !filename.hasPrefix(".") {
                        let swiftFilename = "\(path)/\(filename)"

                        print("Filename: \(swiftFilename)")

                        if let file = try? String(contentsOfFile: swiftFilename, encoding: .utf8) {
                            let output = rx1.withMatchesReplaced(string: file) { match in
                                let paragraphs = rx4.split(string: rx2.withMatchesReplaced(string: match.subString.trimmed) { _ in "" })

                                for paragraph in paragraphs {
                                    let s = rx3.withMatchesReplaced(string: paragraph) { _ in " " }
                                    print(s)
                                }

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

