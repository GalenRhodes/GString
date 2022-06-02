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
    let p01              = #"((?:^(?:[ \t]+///)(?:.*)(?:\r\n?|\n))+)"#
    let fm:  FileManager = FileManager.default
    var err: Error?      = nil

    guard let rx = RegularExpression(pattern: p01, error: &err) else {
        print("ERROR: \(err?.localizedDescription ?? "")")
        return 1
    }

    guard let inputStream: InputStream = InputStream(fileAtPath: "DocFixerConfig.json") else {
        print("ERROR: Config file could not be found.")
        return 1
    }

    do {
        let da
    }
    catch let e {
    }

    if let e: FileManager.DirectoryEnumerator = fm.enumerator(atPath: "") {
    }

    return 0
}
