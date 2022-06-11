/*===============================================================================================================================================================================*
 *     PROJECT: GString
 *    FILENAME: DFConfig.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: June 10, 2022
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

class DFConfig: Decodable {
    enum CodingKeys: String, CodingKey {
        case project      = "project"
        case remoteHost   = "remote-host"
        case remoteUser   = "remote-user"
        case remotePath   = "remote-path"
        case jazzyVersion = "jazzy-version"
        case paths        = "paths"
        case lineWidth    = "line-width"
    }

    let project:      String
    let remoteHost:   String
    let remoteUser:   String
    let remotePath:   String
    let jazzyVersion: String?
    let lineWidth:    Int
    let paths:        [String]

    required init(from decoder: Decoder) throws {
        let pi:         ProcessInfo                        = ProcessInfo()
        let values:     KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        let _project:   String                             = try values.decode(String.self, forKey: .project)
        let _lineWidth: Int                                = try values.decodeIfPresent(Int.self, forKey: .lineWidth) ?? 132

        project = _project
        lineWidth = _lineWidth

        let _remoteHost:    String                   = try values.decodeIfPresent(String.self, forKey: .remoteHost) ?? "localhost"
        let _remoteUser:    String                   = try values.decodeIfPresent(String.self, forKey: .remoteUser) ?? pi.userName
        let _remotePath:    String                   = try values.decodeIfPresent(String.self, forKey: .remotePath) ?? "/var/www/html/\(_project)"
        let _jazzyVersion:  String?                  = try values.decodeIfPresent(String.self, forKey: .jazzyVersion)
        var _pathContainer: UnkeyedDecodingContainer = try values.nestedUnkeyedContainer(forKey: .paths)
        var p:              [String]                 = []

        while !_pathContainer.isAtEnd { try p.append(_pathContainer.decode(String.self)) }

        let handler: String.MacroHandler = { name in
            switch name {
                case CodingKeys.project.rawValue:      return _project
                case CodingKeys.remoteHost.rawValue:   return _remoteHost
                case CodingKeys.remoteUser.rawValue:   return _remoteUser
                case CodingKeys.remotePath.rawValue:   return _remotePath
                case CodingKeys.jazzyVersion.rawValue: return _jazzyVersion
                case CodingKeys.lineWidth.rawValue:    return "\(_lineWidth)"
                default:
                    guard name.hasPrefix("ENV:") else { return nil }
                    guard let i = name.firstIndex(of: ":") else { return nil }
                    return pi.environment[String(name[name.index(after: i)...])]
            }
        }

        remoteHost = try _remoteHost.replacingMacrosUsing(handler)
        remoteUser = try _remoteUser.replacingMacrosUsing(handler)
        remotePath = try _remotePath.replacingMacrosUsing(handler)

        if let v = _jazzyVersion { jazzyVersion = try v.replacingMacrosUsing(handler) }
        else { jazzyVersion = _jazzyVersion }

        for i in (p.startIndex ..< p.endIndex) {
            p[i] = try p[i].replacingMacrosUsing(handler)
        }
        paths = p
    }

    class func loadConfig(configFilename: String) throws -> DFConfig {
        let jd: JSONDecoder = JSONDecoder()
        jd.allowsJSON5 = true
        return try jd.decode(DFConfig.self, from: String(contentsOfFile: configFilename, encoding: .utf8).data(using: .utf8)!)
    }
}
