//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


public typealias ServiceRequestCompletionBlock = (ServiceRequest, [Error]) -> Void


/**
 Encapsulates information about a specific request. By using request payloads, you
 can easily recreate requests (for example, if your services include retry,
 try-and-forward, etc. mechanisms), cache responses, etc.
*/
public protocol ServiceRequestPayload {
    func values() -> [String : String]
    func hashValue() -> Int
}


/// An empty service request for requests that require no payload; typealias to a specific payload type to use
open class EmptyServiceRequestPayload: ServiceRequestPayload {
    // MARK: - Initializers

    public init() {
        let uuidString = UUID().uuidString
        
        self.hashString = "\(uuidString)"
    }

    // MARK: - Protocols

    // MARK: <ServiceRequestPayload>

    open func values() -> [String : String] {
        return [String : String]()
    }

    open func hashValue() -> Int {
        return hashString.hashValue
    }
    
    
    // MARK: - Private

    fileprivate let hashString: String
}


/// A combination of endpoint and payload to uniquely identify specific request attempts.
public struct ServiceRequestIdentifier: Hashable {
    let endpoint: ServiceEndpoint
    let payload: ServiceRequestPayload

    public var hashValue: Int {
        return endpoint.identifier.hashValue ^ payload.hashValue()
    }


    // MARK: - Initialization

    init(endpoint: ServiceEndpoint, payload: ServiceRequestPayload) {
        self.endpoint = endpoint
        self.payload = payload
    }
}


public func == (lhs: ServiceRequestIdentifier, rhs: ServiceRequestIdentifier) -> Bool {
    return (lhs.endpoint.identifier == rhs.endpoint.identifier) && (lhs.payload.hashValue() == rhs.payload.hashValue())
}

public enum ServiceRequestMethod {
    case data
    case download
}

/**
 Turns an `ServiceEndpoint` into an `NSURLRequest` by assigning the endpoint a locator
 path or substituting variables to get the HTTP endpoint, then builds the request by
 filling in the body using a `ServiceRequestConfigurator` and using a set of
 `ServiceRequestDecorator` behaviors to prepare the request.

 A typical pattern for generating a request would be:

 1. Generate an `ServiceRequestPayload` containing information pertinent to the request.
 2. Init an `ServiceRequestConfigurator` of the appropriate type using the payload.
 3. Fetch a `ServiceRequest` using the `Service` responsible for handling the request.
 4. Generate an `NSURLRequest` from the request and active session via `URLRequest(session:)`.
*/
public struct ServiceRequest {
    // MARK: - Properties

    public let endpoint: ServiceEndpoint
    public var url: URL?

    public let payload: ServiceRequestPayload?
    let configurator: ServiceRequestConfigurator?

    let requestMethod: ServiceRequestMethod

    // MARK: - Initialization

    public init?(endpoint: ServiceEndpoint, payload: ServiceRequestPayload? = nil, configurator: ServiceRequestConfigurator? = nil, requestMethod: ServiceRequestMethod = .download) {
        
        self.endpoint = endpoint

        self.payload = payload
        self.configurator = configurator
        self.requestMethod = requestMethod
        
        if let configurator = configurator {
            self.url = configurator.configureURL(self)
        } else {
            self.url = endpoint.url() as URL?
        }
    }


    // MARK: - Public

    // MARK: URL Requests

    /**
     Turns an `ServiceRequest` into a NSURLRequest by creating a request,
     then giving the configurator and session access to that request to fill in
     information.

     - parameter session: The session (if any) to use to sign the URL request
     (for example, if the `Service` responsible for this request requires OAuth
     or other HTTP-request based authentication).
     */
    public func makeURLRequest(_ session: ServiceSession?) -> URLRequest? {
        guard let url = url else { return nil }

        var request = NSMutableURLRequest(url: url)
        request.httpMethod = self.endpoint.type.rawValue

        if let configurator = configurator {
            request = configurator.configureURLRequest(self, urlRequest: request)
        }

        if let session = session {
            request = session.signURLRequest(request)
        }

        return request as URLRequest
    }
}
