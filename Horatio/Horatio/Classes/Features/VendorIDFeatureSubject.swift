//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation
import UIKit


/**
 `FeatureSubject` using the Vendor ID from the iAd framework.
 */
class VendorIDFeatureSubject: FeatureSubject {
    let identifier: String
    
    
    // MARK: - Initialization
    
    init() {
        self.identifier = UIDevice.current.identifierForVendor?.uuidString ?? "<unavailable>"
    }
}
