//
//  RegionMonitor.swift
//  iBeaconApp
//
//  Copyright (c) 2015 mdltorriente. All rights reserved.
//

import CoreLocation

protocol RegionMonitorDelegate: NSObjectProtocol {
    func onBackgroundLocationAccessDisabled()
    func didStartMonitoring()
    func didStopMonitoring()
    func didEnterRegion(region: CLRegion!)
    func didExitRegion(region: CLRegion!)
    func didRangeBeacon(beacon: CLBeacon!, region: CLRegion!)
    func onError(error: NSError)
}


class RegionMonitor: NSObject, CLLocationManagerDelegate {

    var locationManager: CLLocationManager!
    var beaconRegion: CLBeaconRegion?
    var rangedBeacon: CLBeacon! = CLBeacon()
    var pendingMonitorRequest: Bool = false
    
    weak var delegate: RegionMonitorDelegate?
    
    init(delegate: RegionMonitorDelegate) {
        super.init()
        self.delegate = delegate
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
    }
    
    func startMonitoring(beaconRegion: CLBeaconRegion?) {
        print("Start monitoring")
        pendingMonitorRequest = true
        self.beaconRegion = beaconRegion

        switch CLLocationManager.authorizationStatus() {
        case .NotDetermined:
            locationManager.requestAlwaysAuthorization()
        case .Restricted, .Denied, .AuthorizedWhenInUse:
            delegate?.onBackgroundLocationAccessDisabled()
        case .AuthorizedAlways:
            locationManager!.startMonitoringForRegion(beaconRegion!)
            pendingMonitorRequest = false
        }
    }

    func stopMonitoring() {
        print("Stop monitoring")
        pendingMonitorRequest = false
        locationManager.stopRangingBeaconsInRegion(beaconRegion!)
        locationManager.stopMonitoringForRegion(beaconRegion!)
        locationManager.stopUpdatingLocation()
        beaconRegion = nil
        delegate?.didStopMonitoring()
    }

    // MARK: CLLocationManagerDelegate methods

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print("didChangeAuthorizationStatus \(status)")
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            if pendingMonitorRequest {
                locationManager!.startMonitoringForRegion(beaconRegion!)
                pendingMonitorRequest = false
            }
            locationManager!.startUpdatingLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        print("didStartMonitoringForRegion \(region.identifier)")
        delegate?.didStartMonitoring()
        locationManager.requestStateForRegion(region)
    }
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("monitoringDidFailForRegion - \(error)")
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        print("didDetermineState")
        if state == CLRegionState.Inside {
            print(" - entered region \(region.identifier)")
            locationManager.startRangingBeaconsInRegion(beaconRegion!)
        } else {
            print(" - exited region \(region.identifier)")
            locationManager.stopRangingBeaconsInRegion(beaconRegion!)
        }
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion - \(region.identifier)")
        delegate?.didEnterRegion(region)
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("didExitRegion - \(region.identifier)")
        delegate?.didExitRegion(region)
    }
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        print("didRangeBeacons - \(region.identifier)")

        if (beacons.count > 0) {
            rangedBeacon = beacons[0]
            delegate?.didRangeBeacon(rangedBeacon, region: region)
        }
    }

    func locationManager(manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
        print("rangingBeaconsDidFailForRegion \(error)")
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError \(error)")
        if (error.code == CLError.Denied.rawValue) {
            stopMonitoring()
        }
    }
}
