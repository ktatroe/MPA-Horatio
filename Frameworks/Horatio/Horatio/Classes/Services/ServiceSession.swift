//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Handles beginning, ending, and providing access to a service's current session.
*/
public protocol ServiceSessionHandler: class {
    var activeSession: ServiceSession? { get }

    func beginSession(_ session: ServiceSession)
    func endSession()
}


/**
 Provides methods for handling authenticated or verified web services sessions. For
 example, a concrete implementation of the protocol might provide OAuth or
 cookie-based signing of requests.
*/
public protocol ServiceSession: class {
    var isAuthenticated: Bool { get }

    func attemptOpen(_ completion: (() -> Bool)?)
    func close()

    func signURLRequest(_ request: URLRequest) -> URLRequest
}
