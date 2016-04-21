//
//  EnvironmentController.swift
//  Copyright © 2016 PGA Americas. All rights reserved.
//

import Foundation

/*
 Load an environments file to fetch list of environments.
 Determine the active environment: Previously loaded - Defined as active in environments file - first environment in file
 Environments are a key-value store of things that change on per-environment basis (endpoints, behaviors, etc.)
 Values are parsed from config pointed at in environment file, plus items in local config file
 Some types include ServiceEndpoint, Behavior, and WebviewConfig, as well as bare values
 EnvironmentConfigProcessor converts values in a config file into items in a config

 Container.register(Environment.self) { _ in EnvironmentController.currentEnvironment() }

 Once loaded, anything just asks
 
 let activeEnvironment = Container.resolve(Environment.self)
 let someValue = activeEnvironment.value(key: SomeKey)
*/

public typealias EnvironmentConfigValues = [String : AnyObject]


public protocol EnvironmentConfiguration {
    var configProcessors: [EnvironmentConfigProcessor] { get }

    func loadConfiguration()

    func value(forKey key: String) -> AnyObject?
}


public protocol EnvironmentConfigProcessor {
    func process(configValues: EnvironmentConfigValues)
}


public class EnvironmentController {
    struct Behaviors {
        static let PreserveEnvironmentAcrossLaunches = true
    }
    
    let defaultEnvironmentIdentifier: String
    
    private var environments = [Environment]()
    

    // MARK: - Initializers
    
    public init(environments: [Environment], defaultEnvironmentIdentifier: String) {
        self.environments = environments
        self.defaultEnvironmentIdentifier = defaultEnvironmentIdentifier
    }
    
    
    // MARK: - Public
    
    // MARK: Environments
    
    public func currentEnvironment() -> Environment? {
        var foundEnvironment: Environment? = nil
        let defaultsKey = activeEnvironmentDefaultsKey()

        defer {
            if Behaviors.PreserveEnvironmentAcrossLaunches {
                if let foundEnvironment = foundEnvironment {
                    NSUserDefaults.standardUserDefaults().setObject(foundEnvironment.identifier, forKey: defaultsKey)
                }
                else {
                    NSUserDefaults.standardUserDefaults().removeObjectForKey(defaultsKey)
                }

                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
        
        if let previousIdentifier = NSUserDefaults.standardUserDefaults().objectForKey(defaultsKey) as? String {
            if let foundEnvironment = environment(previousIdentifier) {
                return foundEnvironment
            }
        }
        
        if let foundEnvironment = environment(defaultEnvironmentIdentifier) {
            return foundEnvironment
        }
        
        if let foundEnvironment = self.environments.first {
            return foundEnvironment
        }
        
        return nil
    }
    
    
    public func environment(identifier: String) -> Environment? {
        let normalizedIdentifier = identifier.lowercaseString
        
        for environment in environments {
            if normalizedIdentifier == environment.identifier.lowercaseString {
                return environment
            }
        }
        
        return nil
    }

    
    // MARK: - Private

    private func activeEnvironmentDefaultsKey() -> String {
        // TODO: pull from Configuration's config file
        return "activeEnvironment"
    }
}


public class Environment {
    public let identifier: String
    public let name: String
    
    public let configURL: NSURL
    
    private var storedConfigValues = EnvironmentConfigValues()

    
    public init(identifier: String, configURL: NSURL, summary: String? = nil) {
        self.identifier = identifier
        self.name = summary ?? identifier
        
        self.configURL = configURL
    }
}


/// ------- Belong in other source files



public protocol BehaviorProvider {
    func behaviorEnabled(identifier: String) -> Bool
}


public enum WebviewURLStyle {
    case Undefined
    case Inline
    case External
}


public struct WebviewURLConfig {
    let identifier: String
    let url: NSURL
    let style: WebviewURLStyle
    
    public init(identifier: String, url: NSURL, style: WebviewURLStyle) {
        self.identifier = identifier
        self.url = url
        self.style = style
    }
}


public protocol WebviewURLProvider {
    func webviewURLConfig(identifier: String) -> WebviewURLConfig?
}
