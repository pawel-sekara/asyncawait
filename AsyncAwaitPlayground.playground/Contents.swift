//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
@testable import AsyncAwait

enum TestError: Error {
    case mapping
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

let future2 = Future<String>(value: "hehe")

//future.combine(with: future2)

//future.combine(with: future2)

async { do {
    print("execution of async")

//    print(try future.combine(with: future2).await())
        print(try future.await())
        print(try future.await())
    } catch {
        print(error)
    }
}

//PlaygroundPage.current.needsIndefiniteExecution = true

