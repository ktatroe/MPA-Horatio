//
//  JSONServiceResponseProcessor.swift
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
 Processes JSON data in some way — transforming, storing, or otherwise manipulating the data.
 */
public protocol JSONProcessor {
    func processJSONData(request: ServiceRequest, jsonData: JSONObject, completionBlock: (errors: [NSError]?) -> Void)
}


/**
 Processes JSON data from a response object and returns an error or a terminal processed case.
 A JSON processor takes a specialized processor for parsing JSON (typically, parsing the JSON
 into objects and storing those in a local store).
 */
public class JSONServiceResponseProcessor : ServiceResponseProcessor {
    // MARK: - Properties
    
    let jsonProcessor: JSONProcessor
    
    
    // MARK: - Initialization
    
    
    public init(jsonProcessor: JSONProcessor) {
        self.jsonProcessor = jsonProcessor
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ServiceResponseProcessor>
    
    public func process(request: ServiceRequest, input: ServiceResponseProcessorParam, completionBlock: (ServiceResponseProcessorParam) -> Void) {
        var jsonData: JSONObject? = nil
        
        do {
            switch input {
            case .stream(let inputStream):
                jsonData = try NSJSONSerialization.JSONObjectWithStream(inputStream, options: .AllowFragments) as? JSONObject
                
            case .data(_, let inputData):
                jsonData = try NSJSONSerialization.JSONObjectWithData(inputData, options: .AllowFragments) as? JSONObject
                
            default:
                /// TODO: Should this return an error of "no data to process"?
                completionBlock(input)
            }
        }
        catch let jsonError as NSError {
            completionBlock(.error(jsonError))
        }
        
        guard let validJsonData = jsonData else { completionBlock(.processed(false)); return }
        
        jsonProcessor.processJSONData(request, jsonData: validJsonData, completionBlock: { (errors: [NSError]?) in
            if let error = errors?.first {
                completionBlock(.error(error))
                return
            }
            
            completionBlock(.processed(true))
        })
    }
}
