//
// Created by Paweł Sękara on 20.07.2017.
// Copyright (c) 2017 Codewise sp. z o.o. sp. K. All rights reserved.
//

import Foundation


public enum AwaitError: Error {
    case timedOut
    case nilValue
    case cancelled
}