/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Shows how to retrieve the user's location with an operation.
*/

import Foundation
import CoreLocation

/**
    `LocationOperation` is an `Operation` subclass to do a "one-shot" request to
    get the user's current location, with a desired accuracy. This operation will
    prompt for `WhenInUse` location authorization, if the app does not already
    have it.
*/
open class LocationOperation: Operation, CLLocationManagerDelegate {
    // MARK: Properties

    fileprivate let accuracy: CLLocationAccuracy
    fileprivate var manager: CLLocationManager?
    fileprivate let handler: (CLLocation) -> Void

    // MARK: Initialization

    public init(accuracy: CLLocationAccuracy, locationHandler: @escaping (CLLocation) -> Void) {
        self.accuracy = accuracy
        self.handler = locationHandler
        super.init()
        addCondition(LocationCondition(usage: .whenInUse))
        addCondition(MutuallyExclusive<CLLocationManager>())
    }

    override open func execute() {
        DispatchQueue.main.async {
            /*
                `CLLocationManager` needs to be created on a thread with an active
                run loop, so for simplicity we do this on the main queue.
            */
            let manager = CLLocationManager()
            manager.desiredAccuracy = self.accuracy
            manager.delegate = self
            manager.startUpdatingLocation()

            self.manager = manager
        }
    }

    override open func cancel() {
        DispatchQueue.main.async {
            self.stopLocationUpdates()
            super.cancel()
        }
    }

    fileprivate func stopLocationUpdates() {
        manager?.stopUpdatingLocation()
        manager = nil
    }

    // MARK: CLLocationManagerDelegate

    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, location.horizontalAccuracy <= accuracy {
            stopLocationUpdates()
            handler(location)
            finish()
        }
    }

    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        stopLocationUpdates()
        finishWithError(error as NSError?)
    }
}
