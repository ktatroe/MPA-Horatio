//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 An `Operation` subclass that parses an app config file from local storage and updates
 the active environment's config values from it.
 */
public class ParseAppConfigOperation: Operation {
    // MARK: Properties

    private let cacheFile: NSURL


    // MARK: Initialization

    public init(cacheFile: NSURL) {
        self.cacheFile = cacheFile

        super.init()

        name = "Parse App Config"
    }


    // MARK: Operation Overrides

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
            guard let json = try NSJSONSerialization.JSONObjectWithStream(stream, options: []) as? EnvironmentConfigValues else { finish(); return }

            if let controller = Container.resolve(EnvironmentController.self), let _ = controller.currentEnvironment() {
                if let configuration = Container.resolve(EnvironmentConfiguration.self) {
                    for processor in configuration.configProcessors {
                        processor.process(json)
                    }
                }
            }

            finish()
        } catch let jsonError as NSError {
            finishWithError(jsonError)
        }
    }
}
