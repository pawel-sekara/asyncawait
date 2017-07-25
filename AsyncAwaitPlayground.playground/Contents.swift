//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
@testable import AsyncAwait

enum TestError: Error {
    case mapping
}


extension Future {
    func map<K>(_ closure: @escaping ((T) throws -> K)) -> Future<K> {
        return Future<K> { (accept, reject) in
            async { do {
                    let value = try self.await()
                    let mapped = try closure(value)
                    accept(mapped)
                } catch { reject(error) }
            }
        }
    }
}


func doSomethingAsync(_ completion: @escaping (Int) -> ()) {
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
        completion(1234)
    }
}

func doSomethingInFuture() -> Future<Int> {
    return Future { (accept, reject) in
        doSomethingAsync({ (value) in
            accept(value)
        })
    }
}


let future = doSomethingInFuture().map { (value) -> String in

    return "Mapped \(value)"
}

async { do {
    print("execution of async")
        print(try future.await())
        print(try future.await())
    } catch {
        print(error)
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true

