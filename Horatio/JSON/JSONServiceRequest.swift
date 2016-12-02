//
//  JSONServiceRequest.swift
//  Copyright © 2016 Mudpot Apps. All rights reserved.
//

import Foundation


open class JSONBodyServiceRequestConfigurator: ServiceRequestConfigurator {
    let parameters: JSONObject
    
    public init(parameters: JSONObject) {
        self.parameters = parameters
    }
    
    // MARK: <ServiceRequestConfigurator>
    
    open func endpointPathTransformers(_ serviceRequest: ServiceRequest) -> [ServiceEndpointPathTransformer] {
        return [ServiceEndpointPathTransformer]()
    }
    
    open func urlRequestDecorators(_ serviceRequest: ServiceRequest) -> [ServiceRequestDecorator] {
        var decorators = [ServiceRequestDecorator]()
        
        decorators.append(JSONHeadersServiceRequestDecorator())
        decorators.append(AcceptGZIPHeadersServiceRequestDecorator())
        
        decorators.append(JSONBodyParametersServiceRequestDecorator(parameters: parameters))
        
        return decorators
    }
}


/**
 Adds HTTP headers indicating the response is expected (and allowed) to be in JSON format.
 */
open class JSONHeadersServiceRequestDecorator: ServiceRequestDecorator {
    public init() {
        
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceRequestDecorator>
    
    open func compose(_ urlRequest: NSMutableURLRequest) {
        urlRequest.setValue("application/json, text/javascript, */*; q=0.01", forHTTPHeaderField:"Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}


/**
 Applies its parameters in a JSON object in the body of the HTTP request.
 */
open class JSONBodyParametersServiceRequestDecorator: ServiceRequestDecorator {
    // MARK: - Properties
    
    let parameters: JSONObject
    
    
    // MARK: - Initialization
    
    public init(parameters: JSONObject) {
        self.parameters = parameters
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceRequestDecorator>
    
    open func compose(_ urlRequest: NSMutableURLRequest) {
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            urlRequest.httpBody = data
        } catch { }
    }
}
