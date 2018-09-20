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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

