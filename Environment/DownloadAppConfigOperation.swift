//
//  DownloadAppConfigOperation.swift
//  Copyright © 2016 PGA Americas. All rights reserved.
//

import Foundation
import UIKit


/**
An `Operation` subclass that downloads the app config file for the active environment and device
type and stores it in a known location for later parsing.
*/
public class DownloadAppConfigOperation: GroupOperation {
    // MARK: Properties
    
    private let cacheFile: NSURL
    
    
    // MARK: Initialization
    
    public init(cacheFile: NSURL) {
        self.cacheFile = cacheFile

        super.init(operations: [])

        if let controller = Container.resolve(EnvironmentController) {
            guard let environment = controller.currentEnvironment() else { return }
            
            name = "Download App Config"
            
            let task = NSURLSession.sharedSession().downloadTaskWithURL(environment.configURL) { url, response, error in
                self.downloadFinished(url, response: response as? NSHTTPURLResponse, error: error)
            }
            
            let taskOperation = URLSessionTaskOperation(task: task)
            
            // we have to hit the network if we don't have a cached environment
            if let _ = NSData(contentsOfURL: self.cacheFile) {
            }
            else {
                let reachabilityCondition = ReachabilityCondition(host: environment.configURL)
                taskOperation.addCondition(reachabilityCondition)
            }
            
            let networkObserver = NetworkObserver()
            taskOperation.addObserver(networkObserver)
            
            addOperation(taskOperation)
        }
    }
    

    // MARK: Private

    private func downloadFinished(url: NSURL?, response: NSHTTPURLResponse?, error: NSError?) {
        let statusCode = response?.statusCode ?? 500
        
        if statusCode != 200 {
            if let _ = NSData(contentsOfURL: self.cacheFile) {
                // do nothing and let the operation complete
            }
            else if let error = error {
                aggregateError(error)
            }
        }
        else if let localURL = url {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(cacheFile)
            }
            catch { }
            
            do {
                try NSFileManager.defaultManager().moveItemAtURL(localURL, toURL: cacheFile)
            }
            catch let error as NSError {
                aggregateError(error)
            }
            
        }
        else {
            if let _ = NSData(contentsOfURL: self.cacheFile) {
                // do nothing and let the operation complete
            }
            else if let error = error {
                aggregateError(error)
            }
        }
    }
}
