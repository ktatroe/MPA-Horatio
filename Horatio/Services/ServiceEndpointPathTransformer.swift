//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

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
        guard let path = components.path, let newComponents = components.copy() as? NSURLComponents else { return components }
        
        newComponents.path = transformedPath(path)
        
        return newComponents
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
            let identifier = String.init(format: "{%@}", key)

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
                } else {
                    // too few items in the locator chain
                    return path
                }
            } else {
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
