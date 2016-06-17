//
//  ServiceRequestConfigurator.swift
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


/**
 Transforms a `NSURLRequest` into handling a specific request type. For example, a
 concrete implementation might generate a "Create Post" request.
 */
public protocol ServiceRequestConfigurator: class {
    func configureURL(serviceRequest: ServiceRequest) -> NSURL?
    func configureURLRequest(serviceRequest: ServiceRequest, urlRequest: NSMutableURLRequest) -> NSMutableURLRequest
    
    func endpointPathTransformers(serviceRequest: ServiceRequest) -> [ServiceEndpointPathTransformer]
    func urlRequestDecorators(serviceRequest: ServiceRequest) -> [ServiceRequestDecorator]
}


/// Provides base functionality for implementations of `ServiceRequestConfigurator`.
public extension ServiceRequestConfigurator {
    public func configureURL(serviceRequest: ServiceRequest) -> NSURL? {
        switch serviceRequest.endpoint.urlContainer {
        case .components(var components):
            for transformer in endpointPathTransformers(serviceRequest) {
                components = transformer.transformedPath(components)
            }

            return components.URL

        case .absolutePath(let urlString):
            var basePath = urlString

            for transformer in endpointPathTransformers(serviceRequest) {
                basePath = transformer.transformedPath(basePath)
            }

            return NSURL(string: basePath)
        }
    }
    
    
    public func configureURLRequest(serviceRequest: ServiceRequest, urlRequest: NSMutableURLRequest) -> NSMutableURLRequest {
        for decorator in urlRequestDecorators(serviceRequest) {
            decorator.compose(urlRequest)
        }
        
        return urlRequest
    }
}


/**
 Handles a generic key-value store of entries dropped into the URL as GET or POST
 parameters, with no endpoint path transformations.
 */
public class DictionaryServiceRequestConfigurator : ServiceRequestConfigurator {
    // MARK: - Properties

    let parameters: [String : String]
    
    
    // MARK: - Initialization
    
    public init(parameters: [String : String]) {
        self.parameters = parameters
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceRequestConfigurator>
    
    public func endpointPathTransformers(serviceRequest: ServiceRequest) -> [ServiceEndpointPathTransformer] {
        return [ServiceEndpointPathTransformer]()
    }

    public func urlRequestDecorators(serviceRequest: ServiceRequest) -> [ServiceRequestDecorator] {
        let decorator = HTTPParametersBodyServiceRequestDecorator(type: serviceRequest.endpoint.type, parameters: parameters)
        
        return [decorator]
    }
}
