//
//  ServiceEndpointPathTransformer.swift
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
 Implementations of `EndpointPathTransformer` transform a URL's base path. Concrete
 implementations might substitute values or replace the path entirely based on provided
 values.
 */
public protocol ServiceEndpointPathTransformer: class {
    func transformedPath(path: String) -> String
}

extension ServiceEndpointPathTransformer {
    func transformedPath(components: NSURLComponents) -> NSURLComponents {
        guard let path = components.path else { return components }
        components.path = transformedPath(path)
 
        return components
    }
}


/**
 A `EndpointPathTransformer` defined by substitutions; for example,
 "http://example.com/game_[GAMEID].json".
 */
public class SubstitutionsServiceEndpointPathTransformer: ServiceEndpointPathTransformer {
    // MARK: - Properties

    let substitutions: [String : String]
    
    
    // MARK: - Initialization
    
    public init(substitutions: [String : String]) {
        self.substitutions = substitutions
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceEndpointPathTransformer>
    
    public func transformedPath(path: String) -> String {
        var endpointPath = path
        
        for key in substitutions.keys {
            let identifier = String.init(format: "[%@]", key.uppercaseString)
            
            if let value = substitutions[key] {
                endpointPath = endpointPath.stringByReplacingOccurrencesOfString(identifier, withString: value)
            }
        }
        
        return endpointPath
    }
}

/**
 A `EndpointPathTransformer` subclass defined by a RESTful locator chain; for example,
 "http://example.com/:year/game/:id".
 */
public class LocatorChainServiceEndpointPathTransformer: ServiceEndpointPathTransformer {
    // MARK: - Properties

    let locator: [String]

    
    // MARK: - Initialization

    public init(locator: [String]) {
        self.locator = locator
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceEndpointPathTransformer>
    
    public func transformedPath(path: String) -> String {
        var endpointPath = path
        
        var transformedComponents: [String] = []
        var index = 0
        
        for pathPart in endpointPath.componentsSeparatedByString("/") {
            if !pathPart.isEmpty && pathPart.characters[pathPart.startIndex] == ":" {
                if index < locator.count {
                    // replace the next ":(foo)" with the first locator remaining
                    transformedComponents.append(locator[index])
                    
                    index += 1
                }
                else {
                    // too few items in the locator chain
                    return path
                }
            }
            else {
                transformedComponents.append(pathPart)
            }
        }
        
        if index < locator.count {
            // too many values in the locator chain
            return path
        }
        
        endpointPath = transformedComponents.joinWithSeparator("/")
        
        return endpointPath
    }
}
