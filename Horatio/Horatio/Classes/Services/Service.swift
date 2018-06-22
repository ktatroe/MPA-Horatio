//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation

public enum ServiceError: Error {
    case endpointProviderNotFound
}

/**
 Provides access to named `ServiceEndpoint` instances and generates `ServiceRequest`
 instances. Services may also contain a `ServiceSessionHandler` instance (which may
 be shared across services, or unique to particular services).
*/
public protocol Service: class {
    var sessionHandler: ServiceSessionHandler? { get }

    func makeRequest(_ identifier: String, payload: ServiceRequestPayload?, configurator: ServiceRequestConfigurator?, requestMethod: ServiceRequestMethod) throws -> ServiceRequest
}

extension Service {
    public func makeRequest(_ identifier: String, payload: ServiceRequestPayload?, configurator: ServiceRequestConfigurator?, requestMethod: ServiceRequestMethod) throws -> ServiceRequest {
        let endpointProvider = try Container.resolve(ServiceEndpointProvider.self)
        let endpoint = try endpointProvider.endpoint(identifier)
        let request = ServiceRequest(endpoint: endpoint, payload: payload, configurator: configurator, requestMethod: requestMethod)
        
        return request
    }
}
