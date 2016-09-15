//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

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

    var environments = [Environment]()


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
                } else {
                    NSUserDefaults.standardUserDefaults().removeObjectForKey(defaultsKey)
                }

                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }

        if let previousIdentifier = NSUserDefaults.standardUserDefaults().objectForKey(defaultsKey) as? String {
            if let previousEnvironment = environment(previousIdentifier) {
                foundEnvironment = previousEnvironment
                
                return foundEnvironment
            }
        }

        if let defaultEnvironment = environment(defaultEnvironmentIdentifier) {
            foundEnvironment = defaultEnvironment
            
            return foundEnvironment
        }

        if let fallbackEnvironment = self.environments.first {
            foundEnvironment = fallbackEnvironment

            return foundEnvironment
        }

        return nil
    }


    public func environment(identifier: String) -> Environment? {
        let normalizedIdentifier = identifier.lowercased()

        for environment in environments {
            if normalizedIdentifier == environment.normalizedIdentifier {
                return environment
            }
        }

        return nil
    }


    func activeEnvironmentDefaultsKey() -> String {
        return "Horatio:activeEnvironment"
    }
}


public class Environment {
    public let identifier: String
    public let name: String

    public let configURL: NSURL

    public var storedConfigValues = EnvironmentConfigValues()

    public var normalizedIdentifier: String {
        get {
            return identifier.lowercased()
        }
    }

    
    // MARK: - Initialization

    public init(identifier: String, configURL: NSURL, summary: String? = nil) {
        self.identifier = identifier
        self.name = summary ?? identifier

        self.configURL = configURL
    }
}
