//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Transforms a `NSURLRequest` into handling a specific request type. For example, a
 concrete implementation might generate a "Create Post" request.
 */
public protocol ServiceRequestConfigurator: class {
    func configureURL(_ serviceRequest: ServiceRequest) -> URL?
    func configureURLRequest(_ serviceRequest: ServiceRequest, urlRequest: NSMutableURLRequest) -> NSMutableURLRequest

    func endpointPathTransformers(_ serviceRequest: ServiceRequest) -> [ServiceEndpointPathTransformer]
    func urlRequestDecorators(_ serviceRequest: ServiceRequest) -> [ServiceRequestDecorator]
}


/// Provides base functionality for implementations of `ServiceRequestConfigurator`.
public extension ServiceRequestConfigurator {
    public func configureURL(_ serviceRequest: ServiceRequest) -> URL? {
        switch serviceRequest.endpoint.urlContainer {
            case .components(var components):
                for transformer in endpointPathTransformers(serviceRequest) {
                    components = transformer.transformedPath(components)
                }
                
                return components.url

            case .absolutePath(let urlString):
                var basePath = urlString

                for transformer in endpointPathTransformers(serviceRequest) {
                    basePath = transformer.transformedPath(basePath)
                }

                return URL(string: basePath)
        }
    }


    public func configureURLRequest(_ serviceRequest: ServiceRequest, urlRequest: NSMutableURLRequest) -> NSMutableURLRequest {
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
open class DictionaryServiceRequestConfigurator: ServiceRequestConfigurator {
    // MARK: - Properties

    let parameters: [String : String]


    // MARK: - Initialization

    public init(parameters: [String : String]) {
        self.parameters = parameters
    }


    // MARK: - Protocols

    // MARK: <ServiceRequestConfigurator>

    open func endpointPathTransformers(_ serviceRequest: ServiceRequest) -> [ServiceEndpointPathTransformer] {
        return [ServiceEndpointPathTransformer]()
    }

    open func urlRequestDecorators(_ serviceRequest: ServiceRequest) -> [ServiceRequestDecorator] {
        let decorator = HTTPParametersBodyServiceRequestDecorator(type: serviceRequest.endpoint.type, parameters: parameters)

        return [decorator]
    }
}


