//
//  ParseEnvironmentOperation.swift
//  Copyright © 2016 PGA Americas. All rights reserved.
//

import Foundation
import UIKit


/**
An `Operation` subclass that parses the environment file from disk; the file could have been
fetched off network or remain from a previous fetch.
*/
public class ParseEnvironmentsOperation: Operation {
    // MARK: Constants

    struct JSONKeys {
        static let ActiveEnvironmentKey = "activeEnvironment"
        static let EnvironmentsKey = "environments"
        
        static let HandsetConfigKey = "iPhoneConfig"
        static let TabletConfigKey = "iPadConfig"
        static let TVConfigKey = "tvOSConfig"
        
        static let DescriptionKey = "description"
    }
    
    
    // MARK: Properties

    let cacheFile: NSURL
    
    
    // MARK: Initialization

    public init(cacheFile: NSURL) {
        self.cacheFile = cacheFile
        
        super.init()
        
        name = "Parse Environments"
    }
    
    
    // MARK: Overation Overrides

    override public func execute() {
        guard let stream = NSInputStream(URL: cacheFile) else {
            finish()

            return
        }
        
        stream.open()
        
        defer {
            stream.close()
        }
        
        do {
            var parsedEnvironments: [Environment] = []
            
            let json = try NSJSONSerialization.JSONObjectWithStream(stream, options: []) as? [String: AnyObject]
            
            var defaultEnvironmentIdentifier = json?[JSONKeys.ActiveEnvironmentKey] as? String
            
            let environments = json?[JSONKeys.EnvironmentsKey] as? [String: AnyObject]

            var deviceConfigKey: String

            switch UIDevice.currentDevice().userInterfaceIdiom {
            case .Phone:
                deviceConfigKey = JSONKeys.HandsetConfigKey
            case .Pad:
                deviceConfigKey = JSONKeys.TabletConfigKey
            case .TV:
                deviceConfigKey = JSONKeys.TVConfigKey
            default:
                deviceConfigKey = JSONKeys.HandsetConfigKey
            }
            
            if let environments = environments where environments.count > 1 {
                if (defaultEnvironmentIdentifier == nil) {
                    defaultEnvironmentIdentifier = environments.keys.first
                }

                for (identifier, environmentInfo) in environments {
                    let summary = environmentInfo[JSONKeys.DescriptionKey] as? String ?? ""
                    let configURLString = environmentInfo[deviceConfigKey] as? String
                    
                    if let configURLString = configURLString {
                        guard let configURL = NSURL(string: configURLString) else { finish(); return }
                    
                        let environment = Environment(identifier: identifier, configURL: configURL, summary: summary)
                        
                        parsedEnvironments.append(environment)
                    }
                }
            }
            
            let manager = EnvironmentController(environments: parsedEnvironments, defaultEnvironmentIdentifier: defaultEnvironmentIdentifier!)
            Container.register(EnvironmentController.self) { _ in manager }
            
            finish()
        }
        catch let jsonError as NSError {
            finishWithError(jsonError)
        }
    }
}
