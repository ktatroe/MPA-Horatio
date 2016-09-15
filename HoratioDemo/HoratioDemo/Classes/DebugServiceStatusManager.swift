//
//  DebugServiceStatusManager.swift
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 * Neither the name Kevin Tatroe nor the names of its contributors may be
 used to endorse or promote products derived from this software without
 specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation


/*
class ServiceStatusManager {
    struct UserDefaults {
        static let EndpointStatus = "EndpointStatus"

        static let LastUpdatedTemplate = "EndpointFetched:%@:%@"
        static let LastUpdatedStatusTemplate = "EndpointFetchedStatus:%@:%@"
    }

    func lastUpdated(identifier: ServiceRequestIdentifier) -> (ServiceEndpointStatus, NSDate?)
    guard let endpoint = endpoint(identifier) else { return (.Unknown, NSDate.distantPast()) }
    guard endpoint.isIdempotent else { return (.Unknown, NSDate.distantPast()) }

    var endpointStatusValue: [String : AnyObject] = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaults.EndpointStatus) as? [String : AnyObject] ?? [:]
    let hash = endpointSubstitutionHash(substitutions)

    let statusKey = String.init(format: UserDefaults.LastUpdatedStatusTemplate, identifier, hash)

    let lastStatusValue = endpointStatusValue[statusKey] as? Int ?? ServiceEndpointStatus.Unknown.rawValue
    let lastStatus = ServiceEndpointStatus(rawValue: lastStatusValue) ?? .Unknown

    let dateKey = String.init(format: UserDefaults.LastUpdatedTemplate, identifier, hash)
    let lastDate = endpointStatusValue[dateKey] as? NSDate ?? NSDate.distantPast()

    return (lastStatus, lastDate)
}

func touch(identifier: ServiceRequestIdentifier, status: ServiceEndpointStatus = .Success)
guard let endpoint = endpoint(identifier) else { return }
guard endpoint.isIdempotent else { return }

var endpointStatusValue = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaults.EndpointStatus) as? [String : AnyObject] ?? [:]
let hash = endpointSubstitutionHash(substitutions)

let statusKey = String.init(format: UserDefaults.LastUpdatedStatusTemplate, identifier, hash)
endpointStatusValue[statusKey] = status.rawValue

let dateKey = String.init(format: UserDefaults.LastUpdatedTemplate, identifier, hash)
endpointStatusValue[dateKey] = NSDate()

NSUserDefaults.standardUserDefaults().setObject(endpointStatusValue, forKey: UserDefaults.EndpointStatus)
NSUserDefaults.standardUserDefaults().synchronize()


func clearEndpointLastUpdated() {
    NSUserDefaults.standardUserDefaults().removeObjectForKey(UserDefaults.EndpointStatus)
    NSUserDefaults.standardUserDefaults().synchronize()

}

// MARK: Private

private func endpointSubstitutionHash(substitutions: [String : String]) -> String {
    var string = ""

    for (key, value) in substitutions {
        string.appendContentsOf(String.init(format: "|%@=%@", key, value))
    }

    return string
}
}

 */
