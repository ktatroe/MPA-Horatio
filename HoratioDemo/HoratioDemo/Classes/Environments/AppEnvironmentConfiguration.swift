//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 An `EnvironmentConfiguration` that fetches the environments file from a hard-coded,
 remote URL.
 */
class RemoteEnvironmentConfiguration: EnvironmentConfiguration {
    struct ConfigKeys {
        static let EnvironmentURLString = "EnvironmentURL"
    }
    
    
    let environmentURLConfigKey: String


    // MARK: - Properties

    var configProcessors = [EnvironmentConfigProcessor]()


    // MARK: - Initialization

    init(environmentURLConfigKey: String) {
        self.environmentURLConfigKey = environmentURLConfigKey
        
        self.configProcessors.append(AppEnvironmentConfigProcessor())
    }


    // MARK: - Protocols

    // MARK: <EnvironmentConfiguration>

    func loadConfiguration() {
        // do nothing
    }


    func value(forKey key: String) -> AnyObject? {
        switch key {
        case ConfigKeys.EnvironmentURLString:
            guard let remoteURLString = NSBundle.mainBundle().objectForInfoDictionaryKey(environmentURLConfigKey) else {
                assertionFailure("Requesting location permission requires the \(key) key in your Info.plist")
                
                return nil
            }
            
            return remoteURLString

        default:
            return false
        }
    }
}


/**
 An `EnvironmentConfiguration` that loads the environments from a file inside
 the application bundle; should be used only for testing.
 */
class BundleEnvironmentConfiguration: EnvironmentConfiguration {

    struct Filenames {
        static let Environments = "environments_debug"
    }


    // MARK: - Properties

    let environmentBundleFilename: String

    var configProcessors = [EnvironmentConfigProcessor]()
    var configValues = [String : AnyObject]()


    // MARK: - Initialization

    init(environmentBundleFilename: String) {
        self.environmentBundleFilename = environmentBundleFilename
        self.configProcessors.append(AppEnvironmentConfigProcessor())
    }


    // MARK: - Protocols

    // MARK: <EnvironmentConfiguration>

    func loadConfiguration() {
        guard let environmentsURL = NSBundle.mainBundle().URLForResource(environmentBundleFilename, withExtension: "json", subdirectory: nil) else { return }

        if let valueDictionary = NSDictionary(contentsOfURL: environmentsURL) as? EnvironmentConfigValues {
            for (key, value) in valueDictionary {
                configValues[key] = value
            }
        }
    }


    func value(forKey key: String) -> AnyObject? {
        return configValues[key]
    }
}
