/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This code shows how to create a simple subclass of Operation.
 */

import Foundation

/// A closure type that takes a closure as its parameter.
public typealias ContinuationBlockType = (_ error: Error?) -> Void
public typealias BlockType = (_ continueWithError: @escaping ContinuationBlockType) -> Void


/// A sublcass of `Operation` to execute a closure.
open class BlockOperation: Operation {
    fileprivate let block: BlockType
    
    /**
     The designated initializer.
     
     - parameter block: The closure to run when the operation executes. This
     closure will be run on an arbitrary queue. The parameter passed to the
     block **MUST** be invoked by your code, or else the `BlockOperation`
     will never finish executing. If this parameter is `nil`, the operation
     will immediately finish.
     */
    public init(block: @escaping BlockType = { continuation in continuation(nil) }) {
        self.block = block
        super.init()
        name = "Block Operation"
    }
    
    /**
     A convenience initializer to execute a block on the main queue.
     
     - parameter mainQueueBlock: The block to execute on the main queue. Note
     that this block does not have a "continuation" block to execute (unlike
     the designated initializer). The operation will be automatically ended
     after the `mainQueueBlock` is executed.
     */
    public convenience init(mainQueueBlock: @escaping ()->()) {
        self.init(block: { continuation in
            DispatchQueue.main.async {
                mainQueueBlock()
                continuation(nil)
            }
        })
    }
    
    override open func execute() {
        guard !isCancelled else {
            finish()
            return
        }
        
        block { _ in
            self.finish()
        }
    }
}
