//
//  NotificationExtensionTests.swift
//  notification-extension-tests
//
//  Created by Tapash Majumder on 7/6/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableAppExtensions

class NotificationExtensionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let myVal = ITBNotificationServiceExtension()
        myVal.serviceExtensionTimeWillExpire()
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
