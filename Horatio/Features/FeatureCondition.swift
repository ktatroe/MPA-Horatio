//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Determines whether a feature is currently available to a given `FeatureSubject`.
*/
protocol FeatureCondition {
    func isMet(subject: FeatureSubject?) -> Bool
}


/**
 Feature is available conditionally before, after, or during certain dates.
*/
class DateFeatureCondition: FeatureCondition {
    // MARK: - Initialization

    init(startDate: NSDate? = nil, endDate: NSDate? = nil) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    
    // MARK: - Protocols
    
    // MARK: - <FeatureCondition>
    
    func isMet(subject: FeatureSubject?) -> Bool {
        let currentDate = NSDate()
        
        if let startDate = startDate {
            if currentDate.compare(startDate) == NSComparisonResult.OrderedAscending {
                return false
            }
        }
        
        if let endDate = endDate {
            if currentDate.compare(endDate) == NSComparisonResult.OrderedDescending {
                return false
            }
        }
        
        return true
    }
    
    
    // MARK: - Private

    private let startDate: NSDate?
    private let endDate: NSDate?
}


/**
 Feature is available based on the inverse of another condition. (Outside of a certain
 range of dates, for example).
*/
class InverseFeatureCondition: FeatureCondition {
    // MARK: - Initialization
    
    init(condition: FeatureCondition) {
        self.condition = condition
    }
    
    
    // MARK: - Protocols
    
    // MARK: - <FeatureCondition>
    
    func isMet(subject: FeatureSubject?) -> Bool {
        return !condition.isMet(subject)
    }
    
    
    // MARK: - Private

    private let condition: FeatureCondition
}


/**
 Feature is available only when two other conditions are met.
*/
class AndFeatureCondition: FeatureCondition {
    // MARK: - Initialization

    init(lhs: FeatureCondition, rhs: FeatureCondition) {
        self.lhs = lhs
        self.rhs = rhs
    }
    
    
    // MARK: - Protocols
    
    // MARK: - <FeatureCondition>
    
    func isMet(subject: FeatureSubject?) -> Bool {
        return lhs.isMet(subject) && rhs.isMet(subject)
    }
    
    
    // MARK: - Private

    private let lhs: FeatureCondition
    private let rhs: FeatureCondition
}
