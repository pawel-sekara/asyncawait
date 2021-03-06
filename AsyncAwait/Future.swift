//
// Created by Paweł Sękara on 20.07.2017.
//

import Foundation


/**
 *
 *   working -> (success | failure)
 *
 */
open class Future<Value> {
    
    indirect fileprivate enum State {
        case working
        case success(Value)
        case failure(Error)
        case cancelled
        
        mutating func `switch`(_ state: State) {
            guard case .working = self else { return }
            self = state
        }
    }
    
    open var value: Value? {
        if case let .success(value) = _state {
            return value
        }
        return nil
    }
    
    open var error: Error? {
        if case let .failure(error) = _state {
            return error
        } else if case .cancelled = _state {
            return AwaitError.cancelled
        }
        return nil
    }
    
    private var _state: State = .working { didSet { while (_semaphore.signal() != 0) {} } }
    private let _semaphore = DispatchSemaphore(value: 0)
    
    public init(completion: @escaping (_ accept: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
        completion({ (accept) in
            self._state.switch(.success(accept))
        }) { (reject) in
            self._state.switch(.failure(reject))
        }
    }
    
    open func await() throws -> Value {
        return try await(timeoutInterval: .seconds(60))
    }
    
    open func await(timeoutInterval: DispatchTimeInterval) throws -> Value {
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
    
    open func cancel() {
        _state.switch(.cancelled)
    }
    
    
}

/**
 * FutureProtocol - used for generic constraints
 */
public protocol FutureProtocol {
    associatedtype Value
    
    var future: Future<Value> { get }
}

extension Future: FutureProtocol {
    public var future: Future {
        return self
    }
}

public extension Future {
    
    public convenience init(completion: @escaping (@escaping (Value) -> ()) throws -> ()) {
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
    
    public convenience init(error: Error) {
        self.init { (_) in
            throw error
        }
    }
    
    public convenience init(value: Value) {
        self.init { (accept) in
            accept(value)
        }
    }
}

public extension Future {
    
    public func on(completion: ((Value) -> Void)? = nil, failure: ((Error) -> Void)? = nil) -> Future<Value> {
        return Future<Value> { (accept, reject) in
            async {
                do {
                    let value = try self.await()
                    completion?(value)
                    accept(value)
                } catch {
                    failure?(error)
                    reject(error)
                }
            }
        }
    }
}

public extension Future {
    
    public func attemptMap<T>(_ closure: @escaping ((Value) -> (T?, Error?))) -> Future<T> {
        return Future<T> { (accept, reject) in
            async {
                do {
                    let value = try self.await()
                    main {
                        let mapped = closure(value)
                        if mapped.1 != nil {
                            reject(mapped.1!)
                        } else if mapped.0 != nil {
                            accept(mapped.0!)
                        } else {
                            reject(AwaitError.nilValue)
                        }
                    }
                } catch { reject(error) }
            }
        }
    }
    
    @available(*, message: "Do not throw any exception in this closure")
    public func map<T>(_ closure: @escaping ((Value) throws -> T)) -> Future<T> {
        return Future<T> { (accept, reject) in
            async {
                do {
                    let value = try self.await()
                    main {
                        do {
                            let mapped = try closure(value)
                            accept(mapped)
                        } catch {
                            reject(error)
                        }
                    }
                } catch { reject(error) }
            }
        }
    }
    
    public func mapAsync<T>(_ closure: @escaping ((Value) throws -> T)) -> Future<T> {
        return Future<T> { (accept, reject) in
            async {
                do {
                    let value = try self.await()
                    let mapped = try closure(value)
                    accept(mapped)
                } catch { reject(error) }
            }
        }
    }
    
    public func flatMap<T>(_ closure: @escaping ((Value) throws -> Future<T>)) -> Future<T> {
        return Future<T> { (accept, reject) in
            async {
                do {
                    let value = try self.await()
                    let mappedFuture = try closure(value)
                    let resultingValue = try mappedFuture.await()
                    accept(resultingValue)
                } catch {
                    reject(error)
                }
            }
        }
    }
    
    public func combine<A: FutureProtocol>(with future: A) -> Future<(Value, A.Value)> {
        return Future<(Value, A.Value)> { (accept, reject) in
            async {
                
                do {
                    let val = try self.await()
                    let val2 = try future.future.await()
                    accept((val, val2))
                } catch { reject(error) }
            }
        }
    }
    
    public static func combine<A: FutureProtocol, B: FutureProtocol>(_ future1: A, _ future2: B) -> Future<(Value, B.Value)> where A.Value == Value {
        return future1.future.combine(with: future2)
    }
    
}


