//
//  TaskScheduler.swift
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//

import Foundation


public protocol ScheduledTaskProvider {
    var identifier: String { get }
    
    func makeScheduledTask() -> NSOperation?
}


public protocol ScheduledTaskCoordinator {
    func pause()
    func resume()
    
    func scheduleTasks()

    func addTaskProvider(provider: ScheduledTaskProvider)
    func removeTaskProvider(provider: ScheduledTaskProvider)
}


class TimedTaskCoordinator : ScheduledTaskCoordinator {
    struct Behaviors {
        static let TimerInterval: NSTimeInterval = 10.0
    }
    
    var providers = [ScheduledTaskProvider]()
    var isActive = false
    
    var updateTimer: NSTimer?
    
    
    // MARK: - Initialization
    
    init() {
        resume()
    }
    
    
    deinit {
        pause()
    }
    
    
    // MARK: - Protocols
    
    // MARK: <ScheduledTaskCoordinator>
    
    func pause() {
        isActive = false
    }
    
    
    func resume() {
        isActive = true
        
        if updateTimer == nil {
            updateTimer = NSTimer.scheduledTimerWithTimeInterval(Behaviors.TimerInterval, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        }

        if let updateTimer = updateTimer {
            updateTimer.fire()
        }
    }
    
    
    func scheduleTasks() {
        guard isActive else { return }
        guard let queue = Container.resolve(OperationQueue.self) else { return }

        for provider in providers {
            if let operation = provider.makeScheduledTask() {
                queue.addOperation(operation)
            }
        }
    }

    
    func addTaskProvider(provider: ScheduledTaskProvider) {
        providers.append(provider)
    }
    
    
    func removeTaskProvider(provider: ScheduledTaskProvider) {
        guard let index = providers.indexOf({ (testProvider) -> Bool in
            return testProvider.identifier == provider.identifier
        }) else { return }
        
        providers.removeAtIndex(index)
    }
    
    
    // MARK: - Private
    
    @objc
    private func timerFired(timer: NSTimer) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.scheduleTasks()
        }
    }
}
