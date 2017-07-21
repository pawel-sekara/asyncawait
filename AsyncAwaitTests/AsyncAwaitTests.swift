//
//  AsyncAwaitTests.swift
//  AsyncAwaitTests
//
//  Created by Paweł Sękara on 20.07.2017.
//  Copyright © 2017 Codewise sp. z o.o. sp. K. All rights reserved.
//

import XCTest
@testable import AsyncAwait
import Nimble

enum TestError: Error {
    case test
}

class AsyncAwaitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        AsyncAwait.synchronousMode = false
    }

    //TODO: add test for multiple await calls

    func testFutureInit_callbackFiredWithValue_valueIsReceived() {
        let sut = Future<String> { completion in
            completion("Done")
        }

        expect(sut.value) == "Done"
    }

    func testFutureInit_thrownErrorInCallback_errorIsReceived() {
        let sut = Future<String> { completion in
            throw TestError.test
        }

        expect(sut.error).to(matchError(TestError.test))

    }

    func testFutureAwait_awaitCalledInMainThread_fatalErrorIsThrown() {
        let sut = Future<String> { completion in
            completion("Done")
        }

        expect { _ = try sut.await() }.to(throwAssertion())
    }

    func testFutureAwaitTestMode_awaitCalledInMainThread_noErrorIsThrown() {
        AsyncAwait.synchronousMode = true
        let sut = Future<String> { completion in
            completion("Done")
        }

        expect { _ = try sut.await() }.notTo(throwAssertion())
        expect(sut.value) == "Done"
    }

    func testFutureAwait_awaitCalledInAsyncBlock_valueIsReceived() {
        let sut = Future<String> { completion in
            completion("Done")
        }

        var value: String?
        async {
            value = try? sut.await()
        }
        expect(value).toEventually(equal("Done"))

    }

    func testFutureAwait_multipleAwaitCallsInAsyncBlock_operationIsBlockingAndValuesAreReceivedAccordingToTheOrderOfCalls() {
        let sut1 = Future<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
                completion("Done1")
            }
        }
        let sut2 = Future<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
                completion("Done2")
            }
        }

        var array = [String]()
        async {
            do {
                array.append(try sut2.await())
                array.append(try sut1.await())
            } catch {}
        }
        expect(array).toEventually(beginWith("Done2"), timeout: 2.1)
        expect(array).toEventually(endWith("Done1"), timeout: 2.1)
    }

    func testFutureAwait_awaitCalledInAsyncBlockBeingErrorInitialized_exceptionIsThrown() {
        let sut = Future<String> { _ in
            throw TestError.test
        }

        var err: Error?
        async {
            do {
                try sut.await()
            } catch {
               err = error
            }
        }

        expect(err).toEventually(matchError(TestError.test))
    }

    func testFutureAwaitTestMode_awaitCalledInAsyncBlockWithImmediateValue_valueIsReceived() {
        AsyncAwait.synchronousMode = true
        let sut = Future<String> { completion in
            completion("Done")
        }

        async {
            expect(try? sut.await()) == "Done"
        }
    }

    func testFutureAwaitTestMode_awaitCalledInAsyncBlockWithDelayedValue_valueIsReceivedAndOperationIsBlocking() {
        AsyncAwait.synchronousMode = true
        let sut = Future<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
                completion("Done")
            }
        }

        async {
            expect(try? sut.await()) == "Done"
        }
    }
}
