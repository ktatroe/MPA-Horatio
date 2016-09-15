//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/**
 Abstracts the current user of the app to a unique identifier.
*/
protocol FeatureSubject {
    var identifier: String { get }
}


/**
 `FeatureSubject` that assigns a random identifier for the duration of the current session.
*/
class RandomFeatureSubject: FeatureSubject {
    struct Behaviors {
        static let IdentifierLength = 32
    }
    
    
    let identifier: String
    

    // MARK: - Initialization

    init() {
        self.identifier = RandomFeatureSubject.generateRandomIdentifier(Behaviors.IdentifierLength)
    }
    
    
    // MARK: - Private
    
    private static func generateRandomIdentifier(length: Int) -> String {
        let allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let count = UInt32(allowed.characters.count)

        var identifier = ""
        
        for _ in (0 ..< length) {
            let random = Int(arc4random_uniform(count))
            
            let c = allowed[allowed.startIndex.advancedBy(random)]
            identifier += String(c)
        }
        
        return identifier
    }
}
