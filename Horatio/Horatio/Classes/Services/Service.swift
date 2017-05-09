//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Provides access to named `ServiceEndpoint` instances and generates `ServiceRequest`
 instances. Services may also contain a `ServiceSessionHandler` instance (which may
 be shared across services, or unique to particular services).
*/
public protocol Service: class {
    var sessionHandler: ServiceSessionHandler? { get }

    func makeRequest(_ identifier: String, payload: ServiceRequestPayload?, configurator: ServiceRequestConfigurator?) -> ServiceRequest?
}

extension Service {
    public func makeRequest(_ identifier: String, payload: ServiceRequestPayload?, configurator: ServiceRequestConfigurator?) -> ServiceRequest? {
        if let endpointProvider = Container.resolve(ServiceEndpointProvider.self) {
            if let endpoint = endpointProvider.endpoint(identifier) {
                let request = ServiceRequest(endpoint: endpoint, payload: payload, configurator: configurator)

                return request
            }
        }

        return nil
    }
}
