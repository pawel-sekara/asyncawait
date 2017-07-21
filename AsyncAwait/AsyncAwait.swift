//
// Created by Paweł Sękara on 20.07.2017.
// Copyright (c) 2017 Codewise sp. z o.o. sp. K. All rights reserved.
//

import Foundation

public class AsyncAwait {
    static let async = DispatchQueue(label: "com.codewise.async", attributes: .concurrent)
    public static var synchronousMode = false {
        didSet {
            if synchronousMode && (NSClassFromString("XCTest") == nil) {
                print("WARNING: Synchronous mode has been turned on, make sure app is in test mode.")
            }
        }
    }

    public static func async(invoke: @escaping () -> ()) {
        if isTesting {
            invoke()
        } else {
            async.async {
                invoke()
            }
        }
    }

    public static func main(invoke: @escaping () -> ()) {
        if isTesting {
            invoke()
        } else {
            DispatchQueue.main.async {
                invoke()
            }
        }
    }

    static var isTesting: Bool {
        return (NSClassFromString("XCTest") != nil) && synchronousMode
    }
}


func async(invoke: @escaping () -> ()) {
    AsyncAwait.async(invoke: invoke)
}

func main(invoke: @escaping () -> ()) {
    AsyncAwait.main(invoke: invoke)
}
