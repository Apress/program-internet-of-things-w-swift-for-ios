//
//  SecondViewController.swift
//  CarFinder
//
//  Created by Ahmed Bakir on 10/28/15.
//  Copyright © 2015 Ahmed Bakir. All rights reserved.
//

import UIKit
import MapKit

class SecondViewController: UIViewController {

    @IBOutlet var mapView : MKMapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let locations = DataManager.sharedInstance.locations
        var annotations = [MKPointAnnotation]()
        
        for location in locations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotations.insert(annotation, atIndex: annotations.count)
        }
        
        let oldAnnotations = mapView!.annotations
        mapView?.removeAnnotations(oldAnnotations)
        
        mapView?.addAnnotations(annotations)
        
        if (annotations.count > 0) {
            let region = MKCoordinateRegionMake(annotations[0].coordinate, MKCoordinateSpanMake(0.1, 0.1))
            mapView?.regionThatFits(region)
        }
        mapView?.showsUserLocation = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

