//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
@testable import AsyncAwait

enum TestError: Error {
    case mapping
}


func doSomethingAsync(_ completion: @escaping (Int) -> ()) {
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
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

var someFuture: Future<Int>?



async { do {
    someFuture = doSomethingInFuture()
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1), execute: {
        someFuture?.cancel()
        someFuture = nil
    })

    if let val = try someFuture?.await() {
        print(val)
    } else {
        print("no val")
    }
//    print(try future.combine(with: future2).await())

    } catch {
        print(error)
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true

