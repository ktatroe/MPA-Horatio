//
//  ServiceEndpoint.swift
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


/// The HTTP request type of an endpoint.
public enum ServiceEndpointType : String {
    /// Fetch data for an HTTP resource (i.e., GET)
    case get = "GET"
    
    /// Update data for an HTTP resource (i.e., POST)
    case post = "POST"
    
    /// Create a new HTTP resource (i.e., PUT)
    case put = "PUT"
    
    /// Delete an existing HTTP resource (i.e., DELETE)
    case delete = "DELETE"
    
    /// Fetch headers for an HTTP service (i.e., HEADER)
    case header = "HEADER"
}


/**
 Stores and provides named `ServiceEndpoint` instances. Each application will
 generally have a single `ServiceEndpointProvider` active at any given moment,
 but can switch between them as necessary (for example, when switching environments).
 */
public protocol ServiceEndpointProvider: class {
    func endpoint(identifier: String) -> ServiceEndpoint?
}


/**
 Stores information about a `ServiceEndpoint` URL.
*/
enum ServiceEndpointURLContainer {
    // URL is contained in an `NSURLComponents` object
    case components(NSURLComponents)
    
    // URL is contained in a self-contained complete URL
    case absolutePath(String)
}

/**
 Abstracts details of an API endpoint and turning endpoint information into `NSURL`
 instances (which can then be turned into `NSURLRequest` instances via the
 appropriate `Service`).
 */
public class ServiceEndpoint {
    // MARK: - Properties
    
    public let identifier: String
    
    var urlContainer: ServiceEndpointURLContainer
    
    public var type: ServiceEndpointType = .get
    
    public var isAuthRequired: Bool = false
    public var isIdempotent: Bool = true
    
    
    // MARK: - Initialization
    
    public init(identifier: String) {
        self.identifier = identifier
        self.urlContainer = .absolutePath("")
    }
    
    
    public convenience init(identifier: String, scheme: String, hostName: String, basePath: String, path: String) {
        self.init(identifier: identifier)
        
        let components = NSURLComponents()
        components.scheme = scheme
        components.host = hostName
        components.path = "\(basePath)/\(path)"
        
        self.urlContainer = .components(components)
    }

    
    public convenience init(identifier: String, path: String) {
        self.init(identifier: identifier)
        
        self.urlContainer = .absolutePath(path)
    }

    
    // MARK: - Public
    
    // MARK: URLs
    
    /**
     Return an `NSURL` created by putting the scheme, host, and base path together. Most
     often, this would be modified by one or more `ServiceEndpointPathTransformer` instances
     attached to a `ServiceRequest`.
     */
    public func url() -> NSURL? {
        switch urlContainer {
        case .components(let components):
            return components.URL
        case .absolutePath(let urlString):
            return NSURL(string: urlString)
        }
    }
}
