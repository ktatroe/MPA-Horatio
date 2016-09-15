//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Processes an environment file fetched either remotely or from the application's
 bundle and turns it into a series of `Environment` instances and a default
 environment identifier (for first launch).
 */
protocol EnvironmentProcessor {
    func process(jsonObject: JSONObject) -> Bool
    
    func environments() -> [Environment]
    func defaultIdentifier() -> String
}


/**
 An `Operation` subclass that parses the environment file from disk; the file could have been
 fetched off network or remain from a previous fetch.
 */
public class ParseEnvironmentsOperation: Operation {
    // MARK: Initialization

    public init(processor: EnvironmentProcessor, cacheFile: NSURL) {
        self.processor = processor
        self.cacheFile = cacheFile

        super.init()

        name = "Parse Environments"
    }


    // MARK: Overation Overrides

    override public func execute() {
        guard let stream = NSInputStream(URL: cacheFile) else {
            finish()

            return
        }

        stream.open()

        defer {
            stream.close()
        }

        do {
            let json = try NSJSONSerialization.JSONObjectWithStream(stream, options: []) as? JSONObject
            
            guard processor.process(json!) else {
                finishWithError(invalidEnvironmentsJSON)
                
                return
            }
            
            let environments = processor.environments()
            let defaultEnvironmentIdentifier = processor.defaultIdentifier()

            guard !environments.isEmpty else {
                finishWithError(environmentsNotFound)

                return
            }

            let manager = EnvironmentController(environments: environments, defaultEnvironmentIdentifier: defaultEnvironmentIdentifier)
            Container.register(EnvironmentController.self) { _ in manager }

            finish()
        } catch let jsonError as NSError {
            finishWithError(jsonError)
        }
    }


    // MARK: - Private

    private let processor: EnvironmentProcessor
    private let cacheFile: NSURL

    private lazy var invalidEnvironmentsJSON: NSError = {
        return NSError(domain: "horatio.environments", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid environments"])
    }()
    
    private lazy var environmentsNotFound: NSError = {
        return NSError(domain: "horatio.environments", code: 3, userInfo: [NSLocalizedDescriptionKey: "No environments found"])
    }()
}
