//
// Created by Paweł Sękara on 20.07.2017.
// Copyright (c) 2017 Codewise sp. z o.o. sp. K. All rights reserved.
//

import Foundation

public protocol FutureType {
    associatedtype Value

    var value: Value? { get }
    var error: Error? { get }

    func await() throws -> Value
}

/**
*
*   working -> (success | failure)
*
*/
open class Future<T>: FutureType {

    indirect fileprivate enum State {
        case working
        case success(T)
        case failure(Error)

        mutating func `switch`(_ state: State) {
            guard case .working = self else { return }
            self = state
        }
    }

    open var value: T? {
        if case let .success(value) = _state {
            return value
        }
        return nil
    }

    open var error: Error? {
        if case let .failure(error) = _state {
            return error
        }
        return nil
    }

    private var _state: State = .working { didSet { _semaphore.signal()  } }
    private let _semaphore = DispatchSemaphore(value: 0)


    public init(completion: @escaping (_ accept: @escaping (T) -> (), _ reject: @escaping (Error) -> ()) -> ()) {
        completion({ [weak self] (accept) in
            self?._state.switch(.success(accept))
        }) { [weak self] (reject) in
            self?._state.switch(.failure(reject))
        }
    }

    open func await() throws -> Value {
        return try await(timeoutInterval: .seconds(60))
    }

    open func await(timeoutInterval: DispatchTimeInterval) throws -> T {
        guard !Thread.isMainThread || AsyncAwait.isTesting else {
            fatalError("Await shall not be called on main thread.")
        }

        if let error = error {
            throw error
        } else if let value = value {
            return value
        }

        let timeout = _semaphore.wait(timeout: .now() + timeoutInterval)

        if case .timedOut = timeout {
            throw AwaitError.timedOut
        } else if let error = error {
            throw error
        } else if value == nil {
            throw AwaitError.nilValue
        }

        return value!
    }

}

public extension Future {

    public convenience init(completion: @escaping (@escaping (T) -> ()) throws -> ()) {
        self.init { (accept, reject) in
            do {
                try completion { value in
                    accept(value)
                }
            } catch {
                reject(error)
            }
        }
    }
}