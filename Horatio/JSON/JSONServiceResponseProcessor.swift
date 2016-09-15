//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Processes JSON data in some way — transforming, storing, or otherwise manipulating the data.
 */
public protocol JSONProcessor {
    func processJSONData(request: ServiceRequest, jsonData: JSONObject, completionBlock: (errors: [NSError]?) -> Void)
    func processJSONData(request: ServiceRequest, jsonData: [JSONObject], completionBlock: (errors: [NSError]?) -> Void)
}


extension JSONProcessor {
    func processJSONData(request: ServiceRequest, jsonData: JSONObject, completionBlock: (errors: [NSError]?) -> Void) {
        completionBlock(errors: nil)
    }
    
    
    func processJSONData(request: ServiceRequest, jsonData: [JSONObject], completionBlock: (errors: [NSError]?) -> Void) {
        completionBlock(errors: nil)
    }
}


/**
 Processes JSON data from a response object and returns an error or a terminal processed case.
 A JSON processor takes a specialized processor for parsing JSON (typically, parsing the JSON
 into objects and storing those in a local store).
 */
public class JSONServiceResponseProcessor: ServiceResponseProcessor {
    // MARK: - Properties

    let jsonProcessor: JSONProcessor


    // MARK: - Initialization


    public init(jsonProcessor: JSONProcessor) {
        self.jsonProcessor = jsonProcessor
    }


    // MARK: - Protocols

    // MARK: <ServiceResponseProcessor>

    public func process(request: ServiceRequest, input: ServiceResponseProcessorParam, completionBlock: (ServiceResponseProcessorParam) -> Void) {
        var jsonData: AnyObject? = nil
        
        do {
            switch input {
            case .stream(let inputStream):
                jsonData = try NSJSONSerialization.JSONObjectWithStream(inputStream, options: .AllowFragments)
                
            case .data(_, let inputData):
                jsonData = try NSJSONSerialization.JSONObjectWithData(inputData, options: .AllowFragments)
                
            default:
                completionBlock(input)
            }
        } catch let jsonError as NSError {
            print("Error parsing response from \(request.url): \(jsonError)")
            completionBlock(.error(jsonError))
        }

        if let jsonObject = jsonData as? JSONObject {
            processObject(request, jsonObject: jsonObject, completionBlock: completionBlock)
        } else if let jsonArray = jsonData as? [JSONObject] {
            processArray(request, jsonArray: jsonArray, completionBlock: completionBlock)
        } else {
            completionBlock(.processed(false))
        }
    }
    
    
    // MARK: - Private

    private func processObject(request: ServiceRequest, jsonObject: JSONObject, completionBlock: (ServiceResponseProcessorParam) -> Void) {

        jsonProcessor.processJSONData(request, jsonData: jsonObject, completionBlock: { (errors: [NSError]?) in
            if let error = errors?.first {
                completionBlock(.error(error))
                return
            }

            completionBlock(.processed(true))
        })
    }


    private func processArray(request: ServiceRequest, jsonArray: [JSONObject], completionBlock: (ServiceResponseProcessorParam) -> Void) {
        jsonProcessor.processJSONData(request, jsonData: jsonArray, completionBlock: { (errors: [NSError]?) in
            if let error = errors?.first {
                completionBlock(.error(error))
                return
            }
            
            completionBlock(.processed(true))
        })
    }
}
