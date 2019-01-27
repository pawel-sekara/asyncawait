//
// Created by Paweł Sękara on 20.07.2017.
//

import Foundation


public enum AwaitError: Error {
    case timedOut
    case nilValue
    case cancelled
}
