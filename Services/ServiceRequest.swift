//
//  ServiceRequest.swift
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name Kevin Tatroe nor the names of its contributors may be
 used to endorse or promote products derived from this software without
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation


public typealias ServiceRequestCompletionBlock = (ServiceRequest, [NSError]) -> Void


/**
 Encapsulates information about a specific request. By using request payloads, you
 can easily recreate requests (for example, if your services include retry,
 try-and-forward, etc. mechanisms), cache responses, etc.
*/
public protocol ServiceRequestPayload {
    func values() -> [String : String]
    func hashValue() -> Int
}


/// A combination of endpoint and payload to uniquely identify specific request attempts.
public struct ServiceRequestIdentifier : Hashable {
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


public func ==(lhs: ServiceRequestIdentifier, rhs: ServiceRequestIdentifier) -> Bool {
    return (lhs.endpoint.identifier == rhs.endpoint.identifier) && (lhs.payload.hashValue() == rhs.payload.hashValue())
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
public struct ServiceRequest
{
    // MARK: - Properties

    public let endpoint: ServiceEndpoint
    public var url: NSURL?

    public let payload: ServiceRequestPayload?
    let configurator: ServiceRequestConfigurator?
    
    
    // MARK: - Initialization
    
    public init?(endpoint: ServiceEndpoint, payload: ServiceRequestPayload? = nil, configurator: ServiceRequestConfigurator? = nil) {
        self.endpoint = endpoint

        self.payload = payload
        self.configurator = configurator

        self.url = endpoint.url()

        if let configurator = configurator {
            self.url = configurator.configureURL(self)
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
    public func makeURLRequest(session: ServiceSession?) -> NSURLRequest? {
        guard let url = url else { return nil }

        var request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = self.endpoint.type.rawValue
        
        if let configurator = configurator {
            request = configurator.configureURLRequest(self, urlRequest: request)
        }
        
        if let session = session {
            session.signURLRequest(request)
        }
        
        return request
    }
}
