//
//  SecondViewController.swift
//  IOTFit
//
//  Created by Ahmed Bakir on 2018/01/07.
//  Copyright © 2018 Ahmed Bakir. All rights reserved.
//

import UIKit
import MapKit

class WorkoutMapViewController: UIViewController {
    
    @IBOutlet weak var mapView : MKMapView?
    
    var securityView: SecurityView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView?.delegate = self
        
        setupSecurityView()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(showSecurityView), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showSecurityView()
        
        guard var locations = WorkoutDataManager.sharedManager.getLastWorkout(), let first = locations.first, let last = locations.last else {
            return
        }
        let startPin = workoutAnnotation(title: "Start", coordinate: first)
        let finishPin = workoutAnnotation(title: "Finish", coordinate: last)
        
        if let oldAnnotations = mapView?.annotations {
            mapView?.removeAnnotations(oldAnnotations)
        }
        
        mapView?.showAnnotations([startPin, finishPin], animated: true)
        
        let workoutRoute = MKPolyline(coordinates: &locations, count: locations.count)
        mapView?.addOverlays([workoutRoute])
    }
    
    func workoutAnnotation(title: String, coordinate: CLLocationCoordinate2D) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        return annotation
    }

    func setupSecurityView() {
        guard let securityNibItems = Bundle.main.loadNibNamed("SecurityView", owner: nil, options: nil),
            let securityView = securityNibItems.first as? SecurityView else { return }
        
        //let securityView = SecurityView(frame: view.frame)
        
        securityView.frame = view.frame
        securityView.autoresizingMask =  [.flexibleWidth, .flexibleHeight]
        securityView.delegate = self
        self.securityView = securityView
        
        view.addSubview(securityView)
    }
    
    @objc func showSecurityView() {
        if let securityView = self.securityView, securityView.isHidden == true {
            securityView.alpha = 1.0
            securityView.isHidden = false
            view.bringSubview(toFront: securityView)
        }
        
        securityView?.checkPasswordExistence()
    }
}

extension WorkoutMapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let pathRenderer = MKPolylineRenderer(overlay: overlay)
        pathRenderer.strokeColor = UIColor.red
        pathRenderer.lineWidth = 3
        return pathRenderer
        
    }
}

extension WorkoutMapViewController: SecurityViewDelegate {
    func needsInitialPassword() {
        let alert = UIAlertController(title: "Initial installation", message: "Please set a passcode for your data", preferredStyle: .alert)
        alert.addTextField { (textField: UITextField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] (action: UIAlertAction) in
            guard let textField = alert.textFields?.first,
                  let password = textField.text else { return }
            self?.securityView?.savePassword(password: password)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func didSavePassword(success: Bool) {
        NSLog("Password save status: \(success)")
    }
    
    func didFinishWithError(description: String) {
        let alert = UIAlertController(title: "Authentication Error", message: description, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true)
    }
    
    func didFinishWithAuthenticationType(_ type: AuthenticationType) {
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            DispatchQueue.main.async {
                self?.securityView?.alpha = 0.0
                self?.securityView?.isHidden = true
                self?.securityView?.passwordTextField?.text = nil
                guard let securityView = self?.securityView else { return }
                self?.view.sendSubview(toBack: securityView)
            }
        })
    }
}
