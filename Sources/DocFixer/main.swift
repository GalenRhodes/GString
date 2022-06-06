//
//  main.swift
//  DocFixer
//
//  Created by Galen Rhodes on 3/26/20.
//  Copyright © 2020 Project Galen. All rights reserved.
//

import Foundation
import RegularExpression

DispatchQueue.main.async { exit(documentationFixer()) }
dispatchMain()

func documentationFixer() -> Int32 {
    do {
        let p01              = #"((?:^(?:[ \t]+///)(?:.*)(?:\r\n?|\n))+)"#
        let fm:  FileManager = FileManager.default
        var err: Error?      = nil

        guard let rx = RegularExpression(pattern: p01, error: &err) else { throw DocFixerError.RegexError(description: err?.localizedDescription ?? "Bad REGEX.") }
        guard let inputStream = InputStream(fileAtPath: "DocFixerConfig.json") else { throw DocFixerError.ConfigFileError(description: "Config file could not be found.") }

        let data = try JSONSerialization.jsonObject(with: inputStream, options: .json5Allowed)
        guard let map = data as? Dictionary<String, Any> else { throw DocFixerError.ConfigFileError(description: "Invalid config file format.") }
        let config = try DFConfig(dataMap: map)

        for path in config.paths {
            if let e: FileManager.DirectoryEnumerator = fm.enumerator(atPath: path) {
            }
        }

        return 0
    }
    catch let e {
        print("ERROR: \(e.localizedDescription)")
        return 1
    }
}

func unURLFilename(_ fn: String) -> String {
    fn.hasPrefix("file://") ? String(fn[fn.index(fn.startIndex, offsetBy: "file://".count) ..< fn.endIndex]) : fn
}

func removeLastSlash(_ fn: String) -> String {
    fn.hasSuffix("/") ? String(fn[fn.startIndex ..< fn.index(before: fn.endIndex)]) : fn
}

func fixFilename(_ fn: String) -> String {
    ((fn as NSString).expandingTildeInPath as String)
}

class DFConfig {
    let project:      String
    let remoteHost:   String
    let remoteUser:   String
    let remotePath:   String
    let jazzyVersion: String?
    let paths:        [String]

    init(dataMap: Dictionary<String, Any>) throws {
        guard let _project = dataMap["project"] as? String else { throw DocFixerError.ConfigFileError(description: "Missing project name.") }

        let rx       = RegularExpression(pattern: #"\$\{([^}]+)\}"#)
        let procInfo = ProcessInfo.processInfo
        var ar       = [
            _project,
            dataMap["remote-host"] as? String ?? "localhost",
            dataMap["remote-user"] as? String ?? "${ENV:USER}",
            dataMap["remote-path"] as? String ?? "/var/www/html/\(_project)",
            dataMap["jazzy-version"] as? String
        ]

        guard let p2 = dataMap["paths"] as? Array<String> else { throw DocFixerError.ConfigFileError(description: "Missing source file path(s).") }
        guard p2.count > 0 else { throw DocFixerError.ConfigFileError(description: "Missing source file path(s).") }

        for i in (ar.startIndex ..< ar.endIndex) {
            if let s = ar[i] {
                var i1 = s.startIndex
                var t  = ""

                rx?.forEachMatch(in: s) { m, _, _ in
                    if let m = m, let r = m[0].range, let k = m[1].subString {
                        t += String(s[i1 ..< r.lowerBound])
                        i1 = r.upperBound

                        switch k {
                            case "project":              t += ((i == 0) ? String(s[r]) : ar[i]!)
                            case "remote-host":          t += ((i == 1) ? String(s[r]) : ar[i]!)
                            case "remote-user":          t += ((i == 2) ? String(s[r]) : ar[i]!)
                            case "remote-path":          t += ((i == 3) ? String(s[r]) : ar[i]!)
                            case "jazzy-version":        t += ((i == 4) ? String(s[r]) : (ar[i] ?? String(s[r])))
                            case "ENV:USER", "username": t += procInfo.userName
                            default:
                                if k.hasPrefix("ENV:"), let x = k.firstIndex(of: ":") {
                                    let y   = String(k[x...])
                                    let env = procInfo.environment
                                    if let ev = env[y] {
                                        t += ev
                                    }
                                    else {
                                        t += String(s[r])
                                    }
                                }
                                else {
                                    t += String(s[r])
                                }
                        }
                    }
                }
                t += String(s[i1...])
                ar[i] = t
            }
        }

        paths = p2
        project = ar[0]!
        remoteHost = ar[1]!
        remoteUser = ar[2]!
        remotePath = ar[3]!
        jazzyVersion = ar[4]
    }
}

enum DocFixerError: Error {
    case ConfigFileError(description: String)
    case RegexError(description: String)
}
