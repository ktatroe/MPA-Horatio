//
//  Horatio.swift
//  Horatio
//
//  Created by Kevin Tatroe on 9/21/18.
//  Copyright © 2018 Mudpot Apps. All rights reserved.
//

import Foundation


//===----------------------------------------------------------------------===//
// Version
//===----------------------------------------------------------------------===//

public class Horatio {
    internal init() { }


    public static func version() -> String {
        let bundle = Bundle(for: Horatio.self)
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        return version
    }
}
