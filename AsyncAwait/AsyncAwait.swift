//
// Created by Paweł Sękara on 20.07.2017.
// Copyright (c) 2017 Codewise sp. z o.o. sp. K. All rights reserved.
//

import Foundation

public struct AsyncAwait {
    internal static let async = DispatchQueue(label: "com.codewise.async", attributes: .concurrent)
    
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

public func async(invoke: @escaping () -> ()) {
    AsyncAwait.async(invoke: invoke)
}

public func main(invoke: @escaping () -> ()) {
    AsyncAwait.main(invoke: invoke)
}


public struct AsyncAwaitExtensionProvider<Base> {
    public let base: Base
    
    fileprivate init(_ base: Base) {
        self.base = base
    }
}

public protocol AsyncAwaitExtension: class {}

public extension AsyncAwaitExtension {
    public var async: AsyncAwaitExtensionProvider<Self> {
        return AsyncAwaitExtensionProvider(self)
    }
    
    public static var async: AsyncAwaitExtensionProvider<Self>.Type {
        return AsyncAwaitExtensionProvider<Self>.self
    }
}



