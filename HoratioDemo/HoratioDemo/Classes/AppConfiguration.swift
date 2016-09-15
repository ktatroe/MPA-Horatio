//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation
import UIKit


/**
 A container for various global configuration values, such as behaviors, endpoints,
 and so on. Implements and is registered as several providers, including the
 `ServiceEndpointProvider`, as well as on its own.
 */
class AppConfiguration: ServiceEndpointProvider, BehaviorProvider, WebviewURLProvider, FeatureProvider {
    struct Values {
        static let ReleaseLastUpdated = "last_updated"
        static let LatestVersion = "latest_version"
        static let MandatoryVersion = "mandatory_version"
        static let AppStoreURL = "appstore_url"
        
        static let AcademicYear = "academic_year"
        static let FeedbackEmailAddress = "feedback_email"
        
        static let ActiveSportIdentifier = "active_sport_identifier"
        
        static let ProductionDFPNetwork = "production_dfp"
    }
    
    struct Endpoints {
        static let TeamLogo = "schoollogo"
    }
    
    struct WebViews {
        static let TermsOfUse = "terms"
        static let PrivacyPolicy = "privacy_policy"
        static let FAQ = "FAQ"
    }

    // MARK: - Initialization
    
    init() {
        self.subject = RandomFeatureSubject()
        
        self.features[FeatureCatalog.UseLocalEnvironments] = StaticFeature(identifier: FeatureCatalog.UseLocalEnvironments, value: .unavailable)

        var debugValue: FeatureValue = .unavailable

        if let infoDictionary = NSBundle.mainBundle().infoDictionary {
            if let debugEnabled = infoDictionary["DebugEnabled"] as? Bool {
                debugValue = debugEnabled ? .available : .unavailable
            }
        }

        self.features[FeatureCatalog.DebugEnabled] = StaticFeature(identifier: FeatureCatalog.DebugEnabled, value: debugValue)
    }

    
    func loadUserDefaults() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        self.values[Values.ActiveSportIdentifier] = userDefaults.objectForKey(Values.ActiveSportIdentifier) as? String ?? "basketball-men"
        self.values[Values.ProductionDFPNetwork] = userDefaults.boolForKey(Values.ProductionDFPNetwork)
    }
    
    
    // MARK: - Properties

    var values = [String : AnyObject]()
    var endpoints = [String : ServiceEndpoint]()
    var behaviors = [String : Bool]()
    var webviewURLConfigs = [String : WebviewURLConfig]()


    func synchronize() {
        let userDefaults = NSUserDefaults.standardUserDefaults()

        userDefaults.setObject(values[Values.ActiveSportIdentifier], forKey: Values.ActiveSportIdentifier)
        
        if let useProductionDFPNetwork = values[Values.ProductionDFPNetwork] as? Bool {
            userDefaults.setBool(useProductionDFPNetwork, forKey: Values.ProductionDFPNetwork)
        }
        
        userDefaults.synchronize()
    }
    
    
    // MARK: - Protocols

    // MARK: <ServiceEndpointProvider>

    func endpoint(identifier: String) -> ServiceEndpoint? {
        return endpoints[identifier]
    }


    // MARK: <BehaviorProvider>

    func behaviorEnabled(identifier: String) -> Bool {
        return behaviors[identifier] ?? false
    }


    // MARK: <WebviewURLProvider>

    func webviewURLConfig(identifier: String) -> WebviewURLConfig? {
        return webviewURLConfigs[identifier]
    }
    
    
    // MARK: <FeatureProvider>
    
    func feature(named: String) -> Feature? {
        return features[named]
    }
    
    
    func activeSubject() -> FeatureSubject? {
        return subject
    }
    
    
    // MARK: - Private
    
    private var subject: FeatureSubject
    private var features = [String : Feature]()
}


/**
 Processes a config file into values, endpoints, behaviors, and webview URLs
 and stores them on the globally-registered `AppConfiguration`.
 */
class AppEnvironmentConfigProcessor: EnvironmentConfigProcessor {
    // MARK: - Protocols

    // MARK: <EnvironmentConfigProcessor>

    func process(configValues: EnvironmentConfigValues) {
        processConfigValues(configValues)
        processEndpoints(configValues)
        processImageEndpoints(configValues)
        processBehaviors(configValues)
        processWebviewURLConfigs(configValues)
    }


    // MARK: - Private

    /// Extract general configuration values from the config dictionary and set them on the active `AppConfiguration`.
    func processConfigValues(configValues: EnvironmentConfigValues) {
        guard let config = Container.resolve(AppConfiguration.self) else { return }

        // App Info
        let appData = configValues["app"] as? EnvironmentConfigValues ?? EnvironmentConfigValues()
        let releaseData = appData["release"] as? EnvironmentConfigValues ?? EnvironmentConfigValues()

        config.values[AppConfiguration.Values.LatestVersion] = JSONParser.parseString(releaseData["latest_version"]) ?? 0
        config.values[AppConfiguration.Values.MandatoryVersion] = JSONParser.parseString(releaseData["mandatory_version"]) ?? 0
        
        if let appStoreURLString = JSONParser.parseString(releaseData["appstore_url"]) {
            if let appStoreURL = NSURL(string: appStoreURLString) {
                config.values[AppConfiguration.Values.AppStoreURL] = appStoreURL
            }
        }

        // General
        let generalData = configValues["default"] as? EnvironmentConfigValues ?? EnvironmentConfigValues()

        let calendar = NSCalendar.currentCalendar()
        let currentYear = calendar.component(.Year, fromDate: NSDate())
        
        config.values[AppConfiguration.Values.AcademicYear] = JSONParser.parseInt(generalData["academic_year"]) ?? currentYear
        config.values[AppConfiguration.Values.FeedbackEmailAddress] = JSONParser.parseString(generalData["feedback_email"])
    }


    /// Extract `ServiceEndpoint` values from the config dictionary and set them on the active `AppConfiguration`.
    func processEndpoints(configValues: EnvironmentConfigValues) {
        guard let config = Container.resolve(AppConfiguration.self) else { return }
        
        guard let apiData = configValues["api"] as? EnvironmentConfigValues else { return }
        guard let baseData = apiData["base"] as? EnvironmentConfigValues else { return }
        guard let endpointsData = apiData["links"] as? EnvironmentConfigValues else { return }

        let baseScheme = baseData["scheme"] as? String
        let baseHost = baseData["host"] as? String
        let basePath = baseData["base_path"] as? String ?? ""
        
        for (identifier, endpointData) in endpointsData {
            guard let path = JSONParser.parseString(endpointData["href"]) else { continue }

            let basePath = JSONParser.parseString(endpointData["base_path"]) ?? basePath
            
            let components = NSURLComponents()
            components.scheme = JSONParser.parseString(endpointData["scheme"]) ?? baseScheme
            components.host = JSONParser.parseString(endpointData["host"]) ?? baseHost
            components.path = "\(basePath)\(path)"
            
            let endpoint = ServiceEndpoint(identifier: identifier)
            endpoint.urlContainer = .components(components)

            config.endpoints[identifier] = endpoint
        }
    }

    
    /// Extract `ServiceEndpoint` values from the config dictionary and set them on the active `AppConfiguration`.
    func processImageEndpoints(configValues: EnvironmentConfigValues) {
        guard let config = Container.resolve(AppConfiguration.self) else { return }
        
        guard let endpointsData = configValues["images"] as? EnvironmentConfigValues else { return }
        
        for (identifier, endpointData) in endpointsData {
            guard let path = JSONParser.parseString(endpointData["href"]) else { continue }

            let endpoint = ServiceEndpoint(identifier: identifier)
            endpoint.urlContainer = .absolutePath(path)
            
            config.endpoints[identifier] = endpoint
        }
    }

    
    /// Extract Behavior switch values from the config dictionary and set them on the active `AppConfiguration`.
    func processBehaviors(configValues: EnvironmentConfigValues) {
        guard let config = Container.resolve(AppConfiguration.self) else { return }

        let behaviorsData = configValues["behaviors"] as? EnvironmentConfigValues ?? EnvironmentConfigValues()
        
        for (key, value) in behaviorsData {
            if let value = value as? Bool {
                config.behaviors[key] = value
            }
        }
    }

    
    /// Extract `WebviewURLConfig` values from the config dictionary and set them on the active `AppConfiguration`.
    func processWebviewURLConfigs(configValues: EnvironmentConfigValues) {
        guard let config = Container.resolve(AppConfiguration.self) else { return }
        
        guard let webviewsData = configValues["webviews"] as? EnvironmentConfigValues else { return }

        for (identifier, webviewData) in webviewsData {
            guard let urlString = JSONParser.parseString(webviewData["href"]) else { continue }
            guard let url = NSURL(string: urlString) else { continue }

            let styleString = JSONParser.parseString(webviewData["style"]) ?? "undefined"
            var style: WebviewURLStyle = .undefined

            switch styleString {
            case "inline":
                style = .inline
            case "external":
                style = .external
            default:
                style = .undefined
            }
            
            let webviewConfig = WebviewURLConfig(identifier: identifier, url: url, style: style)
            config.webviewURLConfigs[identifier] = webviewConfig
        }
    }
}


class FeatureCatalog {
    static let DebugEnabled = "DebugEnabled"
    static let DebugVideoContent = "DebugVideoContent"

    static let UseLocalEnvironments = "UseLocalEnvironments"
    static let UseDebugLiveStream = "UseDebugLiveStream"
    
    static let NotificationsEnabled = "NotificationsEnabled"
    static let NotificationCategoriesEnabled = "NotificationCategoriesEnabled"

    static let Rotation = "Rotation"
}
