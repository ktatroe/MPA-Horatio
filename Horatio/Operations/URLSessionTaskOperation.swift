/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Shows how to lift operation-like objects in to the NSOperation world.
*/

import Foundation

private var URLSessionTaksOperationKVOContext = 0

/**
    `URLSessionTaskOperation` is an `Operation` that lifts an `NSURLSessionTask`
    into an operation.

    Note that this operation does not participate in any of the delegate callbacks \
    of an `NSURLSession`, but instead uses Key-Value-Observing to know when the
    task has been completed. It also does not get notified about any errors that
    occurred during execution of the task.

    An example usage of `URLSessionTaskOperation` can be seen in the `DownloadEarthquakesOperation`.
*/
open class URLSessionTaskOperation: Operation {
    let task: URLSessionTask

    public init(task: URLSessionTask) {
        assert(task.state == .suspended, "Tasks must be suspended.")

        self.task = task

        super.init()
    }

    override open func execute() {
        assert(task.state == .suspended, "Task was resumed by something other than \(self).")

        task.addObserver(self, forKeyPath: "state", options: [], context: &URLSessionTaksOperationKVOContext)

        task.resume()
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &URLSessionTaksOperationKVOContext else { return }
        guard let object = object as? URLSessionTask else { return }

        if object === task && keyPath == "state" && task.state == .completed {
            task.removeObserver(self, forKeyPath: "state")

            if let error = task.error {
                finish([error as NSError])
            } else {
                finish()
            }
        }
    }

    override open func cancel() {
        task.cancel()
        super.cancel()
    }
}
