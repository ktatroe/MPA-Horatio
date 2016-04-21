//
//  NSURL+CacheFiles.swift
//  Copyright © 2016 PGA Americas. All rights reserved.
//

import Foundation


extension NSURL {
    static func cacheFile(named name: String, searchPathDirectory: NSSearchPathDirectory = .CachesDirectory) -> NSURL {
        let cachesDirectory = try! NSFileManager.defaultManager().URLForDirectory(searchPathDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let cacheFileURL = cachesDirectory.URLByAppendingPathComponent(name)

        return cacheFileURL
    }
}
