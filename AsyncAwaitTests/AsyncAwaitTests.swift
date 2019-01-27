//
//  AsyncAwaitTests.swift
//  AsyncAwaitTests
//
//  Created by Paweł Sękara on 20.07.2017.
//

import XCTest
@testable import AsyncAwait
import Nimble

enum TestError: Error {
    case test
    case test2
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

    //MARK: - Init

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

    func testFutureInit_valueIsFiredAndThenErrorIsThrown_valueIsReceived() {
        let sut = Future<String> { completion in
            completion("Done")
            throw TestError.test
        }

        expect(sut.value) == "Done"
        expect(sut.error).to(beNil())
    }

    func testFutureInit_errorIsThrownAndThenValueIsReceived_errorIsReceived() {
        let sut = Future<String> { completion in
            throw TestError.test
            completion("Done") //will never be executed anyway
        }

        expect(sut.value).to(beNil())
        expect(sut.error).to(matchError(TestError.test))
    }

    func testFutureInit_multipleCompletionsAreFired_firstValueIsReceived() {
        let sut = Future<String> { (completion) in
            completion("Done")
            completion("Done2")
        }

        expect(sut.value) == "Done"
    }

    func testFutureInit_acceptAndRejectBlocksAreCalled_valueIsReceived() {
        let sut = Future<String> { (accept, reject) in
            accept("Done")
            reject(TestError.test)
        }

        expect(sut.value) == "Done"
        expect(sut.error).to(beNil())
    }

    func testFutureInit_multipleAcceptBlocksAreCalled_firstValueIsReceived() {
        let sut = Future<String> { (accept, _) in
            accept("Done")
            accept("Done2")
        }

        expect(sut.value) == "Done"
    }

    func testFutureInit_multipleRejectBlocksAreCalled_firstErrorIsReceived() {
        let sut = Future<String> { (_, reject) in
            reject(TestError.test)
            reject(TestError.test2)
        }

        expect(sut.error).to(matchError(TestError.test))
    }

    func testFutureInit_RejectAndAcceptBlocksAreCalled_errorIsReceived() {
        let sut = Future<String> { (accept, reject) in
            reject(TestError.test)
            accept("Done")
        }

        expect(sut.value).to(beNil())
        expect(sut.error).to(matchError(TestError.test))
    }

    //MARK: - Await in normal mode

    func testFutureAwait_awaitCalledWithVoid_everythingShouldWorkJustFine() {
        let sut = Future<Void> { completion in
            completion(())
        }

        var err: Error?
        async {
            do {
                try sut.await()
            } catch {
                err = error
            }
        }

        expect(sut.value).toEventuallyNot(beNil())
        expect(sut.error).to(beNil())
    }

    func testFutureAwait_awaitCalledInMainThread_fatalErrorIsThrown() {
        let sut = Future<String> { completion in
            completion("Done")
        }

        expect { _ = try sut.await() }.to(throwAssertion())
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

    func testFutureAwait_multipleAwaitCallsFromDifferentFuturesInAsyncBlock_operationIsBlockingAndValuesAreReceivedAccordingToTheOrderOfCalls() {
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

        expect(array).to(haveCount(0))
        expect(array).toEventually(beginWith("Done2"), timeout: 2.1)
        expect(array).to(endWith("Done1"))
    }

    func testFutureAwait_awaitCalledInAsyncBlockBeingErrorInitialized_exceptionIsThrown() {
        let sut = Future<String> { _ in
            throw TestError.test
        }

        var err: Error?
        async {
            do { _ = try sut.await() } catch { err = error }
        }

        expect(err).toEventually(matchError(TestError.test))
    }

    func testFutureAwait_awaitCalledButErrorIsThrownLater_exceptionIsThrown() {
        let sut = Future<String> { (accept, reject) in
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
                reject(TestError.test)
            }
        }

        var err: Error?
        async {
            do { _ = try sut.await() } catch { err = error }
        }

        expect(err).toEventually(matchError(TestError.test), timeout: 1.1)
    }

    func testFutureAwait_multipleAwaitsAreCalledFromTheSameFuture_onlyOneBlockingHappensAndValueIsReceived() {
        let sut = Future<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
                completion("Done")
            }
        }

        var value1: String?
        var value2: String?

        async { do {
            value1 = try sut.await()
            value2 = try sut.await()
        } catch {}}

        expect(value1).toEventually(equal("Done"), timeout: 1.1)
        expect(value2).to(equal("Done"))
    }

    //MARK: - Await in test mode

    func testFutureAwaitTestMode_awaitCalledInMainThread_noErrorIsThrown() {
        AsyncAwait.synchronousMode = true
        let sut = Future<String> { completion in
            completion("Done")
        }

        expect { _ = try sut.await() }.notTo(throwAssertion())
        expect(sut.value) == "Done"
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
    
    func testFutureAwait_awaitCancelled_errorIsThrown() {
        AsyncAwait.synchronousMode = true
        let sut = Future<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2), execute: {
                completion("Done")
            })
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
            sut.cancel()
        }
        
        expect {
            _ = try sut.await()
        }.to(throwError(AwaitError.cancelled))
        
    }
}
