//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import UIKit


class RegisterDefaultsOperation: Operation {
    let registeredDefaults: [String : AnyObject]?
    
    init(registeredDefaults: [String : AnyObject]? = nil) {
        self.registeredDefaults = registeredDefaults
    }
    
    
    override func execute() {
        var defaults = [String : AnyObject]()
        
        if let registeredDefaults = registeredDefaults {
            for (key, value) in registeredDefaults {
                defaults[key] = value
            }
            
            NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
        }
        
        if let appConfiguration = Container.resolve(AppConfiguration.self) {
            appConfiguration.loadUserDefaults()
        }
        
        finish()
    }
}
