//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation

/// A condition that requires all dependencies to have finished without reporting an error.
public struct DependencySuccessCondition: OperationCondition {
    
    public static let name = "DependencySuccess"
    public static let isMutuallyExclusive = false
    
    init() { }
    
    public func dependencyForOperation(_ operation: Operation) -> Foundation.Operation? {
        return nil
    }
    
    public func evaluateForOperation(_ operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        for dependency in operation.dependencies {
            if let fallibleDependency = dependency as? Operation, fallibleDependency.failed {
                let error = NSError(code: .conditionFailed, userInfo: [
                    OperationConditionKey: type(of: self).name
                    ])
                
                completion(.failed(error))
                return
            }
        }
        
        completion(.satisfied)
    }
}
