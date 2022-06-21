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

    func testExample() throws {
        let a = 4
        let b = 2
        let m = min(a, b)

        print("| \(a) | \(b) | \(max(a, b) - m)")

        let _a = (a - m)
        let _b = (b - m)

        print("| \(_a) | \(_b) | \(max(_a, _b) - min(_a, _b))")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
