//
//  DefaultServiceSession.swift
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
class DefaultServiceSession : ServiceSessionHandler {
    var activeSession: ServiceSession? = nil

    func beginSession(session: ServiceSession) {
        endSession()

        activeSession = session
        session.attemptOpen(nil)
    }

    func endSession() {
        guard let activeSession = activeSession else { return }

        activeSession.close()
        self.activeSession = nil
    }
}




/**
 `PassthruServiceSession` provides a default implementation of a session that
 simply passes URLs through to "sign" them.
 */
class PassthruServiceSession : ServiceSession {
    var isAuthenticated: Bool = false

    // MARK: - Protocols

    // MARK: <PassthruServiceSession>

    func attemptOpen(completion: (Void -> Bool)?) {
        isAuthenticated = true

        if let completion = completion {
            completion()
        }
    }

    func close() {
        isAuthenticated = false
    }

    func signURLRequest(request: NSMutableURLRequest) -> NSMutableURLRequest {
        return request
    }
}
*/
