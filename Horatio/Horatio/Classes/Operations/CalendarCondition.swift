/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import EventKit

/// A condition for verifying access to the user's calendar.
public struct CalendarCondition: OperationCondition {

    public static let name = "Calendar"
    public static let entityTypeKey = "EKEntityType"
    public static let isMutuallyExclusive = false

    let entityType: EKEntityType

    public init(entityType: EKEntityType) {
        self.entityType = entityType
    }

    public func dependencyForOperation(_ operation: Operation) -> Foundation.Operation? {
        return CalendarPermissionOperation(entityType: entityType)
    }

    public func evaluateForOperation(_ operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        switch EKEventStore.authorizationStatus(for: entityType) {
            case .authorized:
                completion(.satisfied)

            default:
                // We are not authorized to access entities of this type.
                let error = NSError(code: .conditionFailed, userInfo: [
                    OperationConditionKey: type(of: self).name,
                    type(of: self).entityTypeKey: entityType.rawValue
                ])

                completion(.failed(error))
        }
    }
}

/**
    A private `Operation` that will request access to the user's Calendar/Reminders,
    if it has not already been granted.
*/
private class CalendarPermissionOperation: Operation {
    let entityType: EKEntityType
    let store = EKEventStore()

    init(entityType: EKEntityType) {
        self.entityType = entityType
        super.init()
        addCondition(AlertPresentation())
    }

    override func execute() {
        let status = EKEventStore.authorizationStatus(for: entityType)

        switch status {
            case .notDetermined:
                DispatchQueue.main.async {
                    self.store.requestAccess(to: self.entityType) { granted, error in
                        self.finish()
                    }
                }

            default:
                finish()
        }
    }

}
