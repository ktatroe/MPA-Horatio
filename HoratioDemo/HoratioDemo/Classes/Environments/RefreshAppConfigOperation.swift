//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 A `GroupOperation` subclass that encompasses the operations for initializing the active
 environment, including fetching and parsing the environments file and fetching and parsing
 the app config file corresponding to the active environment and device type.
 */
public class RefreshAppConfigOperation: GroupOperation {
    // MARK: Constants

    struct CacheFiles {
        static let AppConfig = "appConfig.json"
    }


    // MARK: - Initialization

    public init() {
        super.init(operations: [])

        let cacheFile = NSURL.cacheFile(named: CacheFiles.AppConfig)
        
        let feature = Container.resolve(FeatureProvider.self)?.feature(FeatureCatalog.UseLocalEnvironments)
        var loadAppConfig: NSOperation
        
        if let feature = feature where feature.isAvailable() {
            loadAppConfig = LoadLocalAppConfigOperation(cacheFile: cacheFile)
        } else {
            loadAppConfig = DownloadAppConfigOperation(cacheFile: cacheFile)
        }

        let parseAppConfig = ParseAppConfigOperation(cacheFile: cacheFile)
        parseAppConfig.addDependency(loadAppConfig)

        addOperation(loadAppConfig)
        addOperation(parseAppConfig)

        addCondition(MutuallyExclusive<RefreshAppConfigOperation>())

        name = "Refresh App Config"
    }
}
