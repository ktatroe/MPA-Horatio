//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

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
            urlContainer = .absolutePath(urlString)
        } else {
            let basePath = JSONParser.parseString(data[JSONKeys.BasePath])
            let path = JSONParser.parseString(data[JSONKeys.Path])

            let components = NSURLComponents()
            components.scheme = JSONParser.parseString(data[JSONKeys.Scheme])
            components.host = JSONParser.parseString(data[JSONKeys.HostName])
            components.path = "\(basePath)/\(path)"

            self.urlContainer = .components(components)
        }

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
