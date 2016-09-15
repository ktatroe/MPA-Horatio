//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


public class LoadLocalAppConfigOperation: Operation {
    
    // MARK: - Constants
    
    private struct AppConfig {
        static let Filename = "config_debug"
        static let Extension = "json"
    }
    
    
    // MARK: - Properties
    
    private let cacheFile: NSURL
    
    private lazy var missingLocalFileError: NSError = {
        return NSError(domain: "horatio.environments", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing local environments file"])
    }()
    
    private lazy var invalidDataFromLocalFile: NSError = {
        return NSError(domain: "horatio.environments", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid data from local environments file"])
    }()
    
    
    // MARK: - Initialization
    
    public init(cacheFile: NSURL) {
        self.cacheFile = cacheFile
    }
    
    
    // MARK: - Operation Overrides
    
    override public func execute() {
        guard let filePath = NSBundle.mainBundle().pathForResource(AppConfig.Filename, ofType: AppConfig.Extension) else { finishWithError(missingLocalFileError); return }
        
        let localURL = NSURL(fileURLWithPath: filePath)
        
        do {
            try NSFileManager.defaultManager().removeItemAtURL(cacheFile)
        } catch { }
        
        var localError: NSError? = nil
        
        do {
            try NSFileManager.defaultManager().copyItemAtURL(localURL, toURL: cacheFile)
        } catch let error as NSError {
            localError = error
        }
        
        finishWithError(localError)
    }
}
