//
//  GStringTests.swift
//  GStringTests
//
//  Created by Galen Rhodes on 5/29/22.
//

import XCTest
@testable import GString

class GStringTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStringWrap() throws {
        let s = "             Now is the time for all                   good men to come to the                   aid of their country.              ".wrapTo(lineWidth: 25, separator: "\"\n\"")

        print("[----*----*----*----*----*]")
        print("\"\(s)\"")
    }

//    func testPerformanceExample() throws {
//        self.measure {
//        }
//    }
}
