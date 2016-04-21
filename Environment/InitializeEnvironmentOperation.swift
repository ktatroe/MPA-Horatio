//
//  InitializeEnvironmentOperation.swift
//  Copyright © 2016 PGA Americas. All rights reserved.
//

import Foundation


/**
A `GroupOperation` subclass that encompasses the operations for initializing the active
environment, including fetching and parsing the environments file and fetching and parsing
the app config file corresponding to the active environment and device type.
*/
public class InitializeEnvironmentOperation: GroupOperation {
    // MARK: Constants

    struct CacheFiles {
        static let Environments = "lastEnvironments-2016.json"
        static let AppConfig = "appConfig-2016.json"
    }
    
    
    // MARK: Properties
    
    private let environmentCacheFile = NSURL.cacheFile(named: CacheFiles.Environments)

    
    // MARK: Initialization
    
    public init() {
        super.init(operations: [])

        let downloadEnvironment = DownloadEnvironmentsOperation(cacheFile: environmentCacheFile)
        
        let parseEnvironment = ParseEnvironmentsOperation(cacheFile: environmentCacheFile)
        parseEnvironment.addDependency(downloadEnvironment)
        
        let continueOperation = BlockOperation {
            let refreshAppConfigOperation = RefreshAppConfigOperation()
            refreshAppConfigOperation.addDependency(parseEnvironment)
            
            self.addOperation(refreshAppConfigOperation)
        }
        
        continueOperation.addDependency(parseEnvironment)

        addOperation(downloadEnvironment)
        addOperation(parseEnvironment)
        addOperation(continueOperation)
        
        addCondition(MutuallyExclusive<InitializeEnvironmentOperation>())
    }
}
