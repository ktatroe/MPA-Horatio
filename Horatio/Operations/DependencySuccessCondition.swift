//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation

/// A condition that requires all dependencies to have finished without reporting an error.
public struct DependencySuccessCondition: OperationCondition {
    
    static let name = "DependencySuccess"
    static let isMutuallyExclusive = false
    
    init() { }
    
    func dependencyForOperation(_ operation: Operation) -> Foundation.Operation? {
        return nil
    }
    
    func evaluateForOperation(_ operation: Operation, completion: (OperationConditionResult) -> Void) {
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
