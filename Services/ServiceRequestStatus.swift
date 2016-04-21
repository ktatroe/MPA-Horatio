//
//  ServiceRequestStatus.swift
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


/**
 Provides a mechanism for updating and remembering the last status for each
 endpoint/payload. Typically used for debugging, a concrete implementation might
 also be used to replay failed attempts when circumstances change (for example,
 converting a task to a background task when switching to the background).
 */
public protocol ServiceStatusHandler: class {
    var statuses: [ServiceEndpointResponseStatus] { get }
    
    func isIdle(identifier: ServiceRequestIdentifier) -> Bool
    
    func updateStatus(identifier: ServiceRequestIdentifier, status: ServiceEndpointStatus)
    func lastStatus(identifier: ServiceRequestIdentifier) -> (ServiceEndpointStatus, NSDate?)
}


/// The current state of a request within this `Service`.
public enum ServiceEndpointState : Int16 {
    case waiting
    case fetching
    case parsing
    case complete
}


/// The last-known status for a given endpoint within this `Service`.
public enum ServiceEndpointStatus : Int16 {
    case unknown
    case failure
    case success
}


/**
 Encapsulates the current state of a fetches against a specific request (`ServiceEndpoint`
 and `ServiceRequestPayload` combination) in an informal state machine.
*/
public class ServiceEndpointResponseStatus {
    // MARK: - Properties

    public let identifier: ServiceRequestIdentifier
    
    public var updateDate : NSDate
    
    public var activityState: ServiceEndpointState = .waiting
    public var status : ServiceEndpointStatus = .unknown
    
    public var error : NSError?
    public var urlResponse: NSURLResponse?
    
    
    // MARK: - Initialization
    
    public init(identifier: ServiceRequestIdentifier) {
        self.identifier = identifier
        
        self.updateDate = NSDate.distantPast()
    }

    
    // MARK: - Public

    // MARK: Status Updates
    
    /**
     Indicate that this status has moved from Idle to starting a fetch.
    */
    public func startFetch() {
        changeState(.fetching)
    }
    
    /**
     Indicate that this status has completed fetching and has begun parsing.
     
     - parameter response: The `NSURLResponse` that completed, causing the
     status to transition to the parsing state.
     */
    public func startParse(response: NSURLResponse? = nil) {
        urlResponse = response

        changeState(.parsing)
    }
    
    /**
     Indicate that this status completed with the provided error.
     
     - parameter completionError: The error that prevented the status from completing
     successfilly.
     */
    public func completeWithError(completionError: NSError?) {
        status = .failure
        error = completionError

        changeState(.complete)
    }
    
    /**
     Indicate that this status has completed successfully.
     */
    public func completeWithSuccess() {
        status = .success
        
        changeState(.complete)
    }
    
    
    // MARK: - Private
    
    private func changeState(state: ServiceEndpointState) {
        guard activityState != .complete else { return }
        guard state != activityState else { return }
        
        activityState = state
        updateDate = NSDate()
    }
}
