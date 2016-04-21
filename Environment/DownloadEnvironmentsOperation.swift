//
//  DownloadEnvironmentOperation.swift
//  Copyright © 2016 PGA Americas. All rights reserved.
//

import Foundation


/**
A `GroupOperation` subclass that wraps fetching the environments endpoint and saving
it to a cache location for parsing later.
*/
public class DownloadEnvironmentsOperation: GroupOperation {
    // MARK: Properties
    
    let cacheFile: NSURL
    
    
    // MARK: Initialization
    
    public init(cacheFile: NSURL) {
        self.cacheFile = cacheFile
        
        super.init(operations: [])
        
        guard let configuration = Container.resolve(EnvironmentConfiguration.self) else { return }
        guard let environmentURLString = configuration.value(forKey: "EnvironmentURL") as? String else { return }
        
        if let url = NSURL(string: environmentURLString) {
            let task = NSURLSession.sharedSession().downloadTaskWithURL(url) { url, response, error in
                self.downloadFinished(url, response: response as? NSHTTPURLResponse, error: error)
            }
            
            let taskOperation = URLSessionTaskOperation(task: task)
            
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
