//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

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

                // must do this after transforms have happened
                rectifyEmbeddedQuery(components)

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

    /**
     Handles the case where there are query parameters embedded in the path. Properly
     pulls them out and merges them into the query.
     */
    private func rectifyEmbeddedQuery(components: NSURLComponents) {
        guard let path = components.path, range = path.rangeOfString("?") else { return }

        components.path = path.substringToIndex(range.startIndex)
        let queryString = path.substringFromIndex(range.startIndex.advancedBy(1))

        var queryItems = [NSURLQueryItem]()

        if let existingQuery = components.queryItems {
            queryItems.appendContentsOf(existingQuery)
        }

        // let it parse the query for us
        components.query = queryString

        if let newQuery = components.queryItems {
            queryItems.appendContentsOf(newQuery)
        }

        components.queryItems = queryItems
    }
}


/**
 Handles a generic key-value store of entries dropped into the URL as GET or POST
 parameters, with no endpoint path transformations.
 */
public class DictionaryServiceRequestConfigurator: ServiceRequestConfigurator {
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


