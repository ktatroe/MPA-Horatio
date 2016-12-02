//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Determines whether a feature is currently available to a given `FeatureSubject`.
*/
protocol FeatureCondition {
    func isMet(_ subject: FeatureSubject?) -> Bool
}


/**
 Feature is available conditionally before, after, or during certain dates.
*/
class DateFeatureCondition: FeatureCondition {
    // MARK: - Initialization

    init(startDate: Date? = nil, endDate: Date? = nil) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    
    // MARK: - Protocols
    
    // MARK: - <FeatureCondition>
    
    func isMet(_ subject: FeatureSubject?) -> Bool {
        let currentDate = Date()
        
        if let startDate = startDate {
            if currentDate.compare(startDate) == ComparisonResult.orderedAscending {
                return false
            }
        }
        
        if let endDate = endDate {
            if currentDate.compare(endDate) == ComparisonResult.orderedDescending {
                return false
            }
        }
        
        return true
    }
    
    
    // MARK: - Private

    fileprivate let startDate: Date?
    fileprivate let endDate: Date?
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
    
    func isMet(_ subject: FeatureSubject?) -> Bool {
        return !condition.isMet(subject)
    }
    
    
    // MARK: - Private

    fileprivate let condition: FeatureCondition
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
    
    func isMet(_ subject: FeatureSubject?) -> Bool {
        return lhs.isMet(subject) && rhs.isMet(subject)
    }
    
    
    // MARK: - Private

    fileprivate let lhs: FeatureCondition
    fileprivate let rhs: FeatureCondition
}
