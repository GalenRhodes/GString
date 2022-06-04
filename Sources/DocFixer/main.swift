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
        guard let prj = dataMap["project"] as? String else { throw DocFixerError.ConfigFileError(description: "Missing project name.") }
        project = prj
        remoteHost = dataMap["remote-host"] as? String ?? "localhost"
        remoteUser = dataMap["remote-user"] as? String ?? "${ENV:USER}"
        remotePath = dataMap["remote-path"] as? String ?? "/var/www/html/\(project)"
        jazzyVersion = dataMap["jazzy-version"] as? String

        guard let a1 = dataMap["paths"] as? NSArray else { throw DocFixerError.ConfigFileError(description: "Missing source file path(s).") }
        var a2: [String] = []
        for x in a1 { if let y = x as? String { a2.append(y) } }
        guard a2.count > 0 else { throw DocFixerError.ConfigFileError(description: "Missing source file path(s).") }
        paths = a2

        let rx = RegularExpression(pattern: #"\$\{([^}]+)\}"#)
        let ar = [ project, remoteHost, remoteUser, remotePath, jazzyVersion ]
    }
}

enum DocFixerError: Error {
    case ConfigFileError(description: String)
    case RegexError(description: String)
}
