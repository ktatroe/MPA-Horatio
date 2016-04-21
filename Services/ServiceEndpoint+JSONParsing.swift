//
//  ServiceEndpoint+JSONParsing.swift
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


extension ServiceEndpoint : JSONParsing {
    struct JSONKeys {
        static let Identifier = "id"
        
        static let URL = "url"
        
        static let Scheme = "protocol"
        static let HostName = "host"
        static let BasePath = "base_path"
        
        static let Path = "path"
        
        static let AuthRequired = "auth_required"
        static let Idempotent = "idempotent"
    }
    
    
    // MARK: - Protocols
    
    // MARK: <JSONParsing>
    
    public func updateFromJSONRepresentation(data: JSONObject) {
        guard self.dynamicType.isValidJSONRepresentation(data) else { return }
        
        if let urlString = JSONParser.parseString(data[JSONKeys.URL]) {
            if let url = NSURL(string: urlString), host = url.host, path = url.path {
                scheme = url.scheme
                self.hostName = host
                
                if let query = url.query {
                    self.basePath = path + "?" + query
                }
                else {
                    self.basePath = path
                }
            }
        }
        
        scheme = JSONParser.parseString(data[JSONKeys.Scheme]) ?? scheme
        hostName = JSONParser.parseString(data[JSONKeys.HostName]) ?? hostName
        basePath = JSONParser.parseString(data[JSONKeys.BasePath]) ?? basePath
        
        path = JSONParser.parseString(data[JSONKeys.Path]) ?? path
        
        isAuthRequired = JSONParser.parseBool(data[JSONKeys.AuthRequired], options: .allowEmpty) ?? isAuthRequired
        isIdempotent = JSONParser.parseBool(data[JSONKeys.Idempotent], options: .allowEmpty) ?? isIdempotent
    }
    
    public static func isValidJSONRepresentation (data: JSONObject) -> Bool {
        // For now our endpoints only include a url key which we must have
        guard let _ = JSONParser.parseString(data[JSONKeys.URL], options: .none) else { return false }
        
        
        guard let _ = JSONParser.parseString(data[JSONKeys.Scheme], options: .allowEmpty) else { return false }
        guard let _ = JSONParser.parseString(data[JSONKeys.HostName], options: .allowEmpty) else { return false }
        guard let _ = JSONParser.parseString(data[JSONKeys.BasePath], options: .allowEmpty) else { return false }
        
        guard let _ = JSONParser.parseString(data[JSONKeys.Path], options: .allowEmpty) else { return false }
        
        guard let _ = JSONParser.parseString(data[JSONKeys.AuthRequired], options: .allowEmpty) else { return false }
        guard let _ = JSONParser.parseString(data[JSONKeys.Idempotent], options: .allowEmpty) else { return false }
        
        return true
    }
}
