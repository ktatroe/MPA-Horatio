//
//  JSONParsingTests.swift
//  HoratioTests
//
//  Created by Ryan Carlson on 4/11/18.
//  Copyright © 2018 Mudpot Apps. All rights reserved.
//

import XCTest
import Horatio

class JSONParsingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSimpleString() {
        let str = "abcd"
        
        let parsedString = JSONParser.parseString(str)
        
        XCTAssertEqual(str, parsedString)
    }
    
    func testJSONString() {
        let str = "{ abcd }"
        
        let parsedString = JSONParser.parseString(str)
        
        XCTAssertEqual(str, parsedString)
    }
    
    func testJSONObjectWithoutQuotes() {
        let str = "{ abc: efg }"
        
        let parsedString = JSONParser.parseString(str)
        
        XCTAssertEqual(str, parsedString)
    }
    
    func testNestedJSONObjectWithoutQuotes() {
        let str = "{ abc: efg, x: { y: z } }"
        
        let parsedString = JSONParser.parseString(str)
        
        XCTAssertEqual(str, parsedString)
    }
    
    func testJSONObjectWithQuotes() {
        let str = "{ \"abc\": \"efg\" }"
        
        let parsedString = JSONParser.parseString(str)
        
        XCTAssertEqual(str, parsedString)
    }
    
    /* this string has an instance of \\u which caused Cru's app to lock up */
    func testOffendingString() {
        let str = "{ abc: \\uxyz \"efg\" }"
        
        let parsedString = JSONParser.parseString(str)
        
        XCTAssertEqual(str, parsedString)
    }
}
