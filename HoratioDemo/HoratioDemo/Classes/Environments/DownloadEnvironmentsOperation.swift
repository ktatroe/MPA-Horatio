//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 A `GroupOperation` subclass that wraps fetching the environments endpoint and saving
 it to a cache location for parsing later.
 */
public class DownloadEnvironmentsOperation: GroupOperation {
    // MARK: Initialization

    public init(cacheFileURL: NSURL) {
        self.cacheFileURL = cacheFileURL

        super.init(operations: [])

        guard let configuration = Container.resolve(EnvironmentConfiguration.self, name: "Remote") else { return }
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

    private let cacheFileURL: NSURL

    
    private func downloadFinished(url: NSURL?, response: NSHTTPURLResponse?, error: NSError?) {
        let statusCode = response?.statusCode ?? 500

        if statusCode != 200 {
            if let _ = NSData(contentsOfURL: cacheFileURL) {
                // do nothing and let the operation complete
            } else if let error = error {
                aggregateError(error)
            }
        } else if let localURL = url {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(cacheFileURL)
            } catch { }

            do {
                try NSFileManager.defaultManager().moveItemAtURL(localURL, toURL: cacheFileURL)
            } catch let error as NSError {
                aggregateError(error)
            }

        } else {
            if let _ = NSData(contentsOfURL: self.cacheFileURL) {
                // cache file exists; do nothing and move on to parsing it
            } else if let error = error {
                aggregateError(error)
            }
        }
    }
}
