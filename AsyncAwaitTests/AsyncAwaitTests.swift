//
//  AsyncAwaitTests.swift
//  AsyncAwaitTests
//
//  Created by Paweł Sękara on 20.07.2017.
//  Copyright © 2017 Codewise sp. z o.o. sp. K. All rights reserved.
//

import XCTest
@testable import AsyncAwait

enum TestError: Error {
    case test
}

class AsyncAwaitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }



    func testFutureInit_callbackFiredWithValue_valueIsReceived() {
        let sut = Future<String> { completion in
            completion("Done")
        }

        XCTAssertEqual(sut.value, "Done")
    }

    func testFutureInit_thrownErrorInCallback_errorIsReceived() {
        let sut = Future<String> { completion in
            throw TestError.test
        }

        XCTAssertNotNil(sut.error)
    }

    func testFutureAwait_awaitCalledInMainThread_fatalErrorIsThrown() {
        let sut = Future<String> { completion in
            completion("Done")
        }

//        XCTAssertThrowsError({
            try? sut.await()
        assertionFailure()
//        })



    }
}
