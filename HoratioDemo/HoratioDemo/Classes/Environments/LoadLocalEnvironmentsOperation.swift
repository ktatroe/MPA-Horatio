//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


public class LoadLocalEnvironmentsOperation: Operation {
    // MARK: - Initialization

    public init(bundleFilename: String, cacheFile: NSURL) {
        self.bundleFilename = bundleFilename
        self.cacheFile = cacheFile
    }


    // MARK: - Overrides

    override public func execute() {
        guard let filePath = NSBundle.mainBundle().pathForResource(self.bundleFilename, ofType: "json") else {
            finishWithError(missingLocalFileError)
            return
        }

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
    
    
    // MARK: - Private

    private let bundleFilename: String
    private let cacheFile: NSURL
    
    private lazy var missingLocalFileError: NSError = {
        return NSError(domain: "horatio.environments", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing local environments file"])
    }()
    
    private lazy var invalidDataFromLocalFile: NSError = {
        return NSError(domain: "horatio.environments", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid data from local environments file"])
    }()
}
