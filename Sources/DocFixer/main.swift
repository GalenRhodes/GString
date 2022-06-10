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
        let fm:  FileManager = FileManager.default
        var err: Error?      = nil

        guard let rx = RegularExpression(pattern: p01, error: &err) else { throw DocFixerError.RegexError(description: err?.localizedDescription ?? "Bad REGEX.") }
        guard let inputStream = InputStream(fileAtPath: "DocFixerConfig.json") else { throw DocFixerError.ConfigFileError(description: "Config file could not be found.") }

        inputStream.open()

        let data = try JSONSerialization.jsonObject(with: inputStream, options: .json5Allowed)
        guard let map = data as? Dictionary<String, Any> else { throw DocFixerError.ConfigFileError(description: "Invalid config file format.") }
        let config = try DFConfig(dataMap: map)

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
                        print("Filename: \(path)/\(filename)")

                        if let file = try? String(contentsOfFile: "\(path)/\(filename)", encoding: .utf8) {
                            rx.forEachMatch(in: file) { m, _, _ in
                                if let m = m {
                                    print(m.subString)
                                }
                            }
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

        guard var p2 = dataMap["paths"] as? Array<String> else { throw DocFixerError.ConfigFileError(description: "Missing source file path(s).") }
        guard p2.count > 0 else { throw DocFixerError.ConfigFileError(description: "Missing source file path(s).") }

        for i in (ar.startIndex ..< ar.endIndex) {
            if let s = ar[i] {
                ar[i] = DFConfig.foo(s, ar, i, rx, procInfo)
            }
        }

        project = ar[Fields.Project.rawValue]!
        remoteHost = ar[Fields.RemoteHost.rawValue]!
        remoteUser = ar[Fields.RemoteUser.rawValue]!
        remotePath = ar[Fields.RemotePath.rawValue]!
        jazzyVersion = ar[Fields.JazzyVersion.rawValue]

        for i in (p2.startIndex ..< p2.endIndex) {
            p2[i] = DFConfig.foo(p2[i], ar, 5, rx, procInfo)
        }
        paths = p2
    }

    private enum Fields: Int {
        case Project      = 0
        case RemoteHost   = 1
        case RemoteUser   = 2
        case RemotePath   = 3
        case JazzyVersion = 4
    }

    private class func foo(_ str: String, _ ar: [String?], _ idx: Int, _ rx: RegularExpression?, _ pi: ProcessInfo) -> String {
        var i = str.startIndex
        var t = ""

        rx?.forEachMatch(in: str) { m, _, _ in
            if let m = m, let r = m[0].range, let k = m[1].subString {
                let macro = String(str[r])
                t += String(str[i ..< r.lowerBound])
                i = r.upperBound

                switch k {
                    case "project":              t += ((idx == 0) ? macro : ar[Fields.Project.rawValue]!)
                    case "remote-host":          t += ((idx == 1) ? macro : ar[Fields.RemoteHost.rawValue]!)
                    case "remote-user":          t += ((idx == 2) ? macro : ar[Fields.RemoteUser.rawValue]!)
                    case "remote-path":          t += ((idx == 3) ? macro : ar[Fields.RemotePath.rawValue]!)
                    case "jazzy-version":        t += ((idx == 4) ? macro : (ar[Fields.JazzyVersion.rawValue] ?? macro))
                    case "ENV:USER", "username": t += pi.userName
                    default:
                        if k.hasPrefix("ENV:"), let x = k.firstIndex(of: ":") {
                            let y   = String(k[x...])
                            let env = pi.environment
                            if let ev = env[y] {
                                t += ev
                            }
                            else {
                                t += macro
                            }
                        }
                        else {
                            t += macro
                        }
                }
            }
        }

        t += String(str[i...])
        return t
    }
}

enum DocFixerError: Error {
    case ConfigFileError(description: String)
    case RegexError(description: String)
}

DispatchQueue.main.async { exit(documentationFixer()) }
dispatchMain()

