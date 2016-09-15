//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


protocol StartupManagerDelegate {
    func coreOperationsCompleted()
}


class StartupManager {
    var startupDelegate: StartupManagerDelegate?


    // MARK: - Public

    func startup() {
        assembleConfiguration()

        assembleFeeds()
        registerContinuousFeeds()
        
        runStartupSequence()
    }


    // MARK: - Private

    // swiftlint:disable force_unwrapping
    // swiftlint:disable function_body_length
    private func assembleConfiguration() {
        Container.register(AppConfiguration.self) { _ in AppConfiguration() }
        Container.register(OperationQueue.self) { _ in OperationQueue() }

        Container.register(EnvironmentConfiguration.self, name: "Remote") { _ in RemoteEnvironmentConfiguration() }
        Container.register(EnvironmentConfiguration.self, name: "BundleFile") { _ in BundleEnvironmentConfiguration() }
        Container.register(EnvironmentConfiguration.self) { _ in Container.resolve(EnvironmentConfiguration.self, name: "BundleFile")! }

        Container.register(ServiceEndpointProvider.self) { _ in Container.resolve(AppConfiguration.self)! }

        Container.register(SportsService.self) { _ in SportsService() }
        Container.register(SportsServiceBridge.self) { _ in WebServicesSportsServiceBridge() }

        Container.register(ScheduledTaskCoordinator.self) { _ in HeartbeatScheduledTaskCoordinator() }
        Container.register(FeedScheduledTaskProvider.self) { _ in FeedScheduledTaskProvider() }
        Container.register(ScheduledTaskProvider.self) { _ in Container.resolve(FeedScheduledTaskProvider.self)! }
        Container.register(FeedProvider.self) { _ in Container.resolve(FeedScheduledTaskProvider.self)! }

        Container.register(FeatureProvider.self) { _ in Container.resolve(AppConfiguration.self)! }
        
        let queue = Container.resolve(OperationQueue.self)!
        queue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    }
    // swiftlint:enable force_unwrapping
    // swiftlint:enable function_body_length


    private func assembleFeeds() {
        guard let provider = Container.resolve(FeedProvider.self) else { return }

        provider.registerFeed(Feed(identifier: FeedScheduledTaskProvider.Identifiers.Sports, refreshStrategy: .ttl(NSTimeInterval(120)), makeOperationBlock: { (resourceID) -> NSOperation? in
            guard let bridge = Container.resolve(SportsServiceBridge.self) else { return nil }
            let payload = FetchSportsRequestPayload()

            return bridge.makeFetchSportsOperation(payload, completion: nil)
        }))
    }


    private func registerContinuousFeeds() {
        guard let taskProvider = Container.resolve(FeedScheduledTaskProvider.self) else { return }

        taskProvider.registerInterest(FeedScheduledTaskProvider.Identifiers.Sports)
    }
    

    private func runStartupSequence() {
        runAsynchronousOperations()
        runSynchronousStartupSequence()
    }
    
    
    private func runAsynchronousOperations() {
        guard let operationQueue = Container.resolve(OperationQueue.self) else { return }

        let startupOperation = StartupSequenceOperation { (error: NSError?) -> Void in
            self.startupDelegate?.coreOperationsCompleted()

            if let taskCoordinator = Container.resolve(ScheduledTaskCoordinator.self) {
                taskCoordinator.resume()
            }
        }

        operationQueue.addOperation(startupOperation)
    }
    
    
    private func runSynchronousStartupSequence() {
    }
}
