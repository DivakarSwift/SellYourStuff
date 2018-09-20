//
//  PostMapVC.swift
//  LetgoClone
//
//  Created by MacBook  on 31.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import MapKit
import Reachability


//burada post ekraninda urunun konumunu gostermek icin kullanidimiz haritanin sinifi
    
class PostMapVC: UIViewController {
    
    var locationManager = CLLocationManager()   //CLLocationManager sayesinde harita işlemlerimizi yapıcaz
    
    var latitude = ""
    var longitude = ""
 

    @IBOutlet weak var mapView: MKMapView!
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        mapView.delegate = self
        locationManager.delegate = self
        
       
        
    }
    
    //burada urunun konum bilgileirni aliyoruz enlem ve boylam haritda isaretliyoruz
    override func viewWillAppear(_ animated: Bool) {
        
        FirebaseVariables.ref.child("posts").child(postUserUid.last!).child(postPhotoUid.last!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            
            self.longitude = value!["boylam"] as! String
            self.latitude = value!["enlem"] as! String
            
            //burada mapview da firebasedem aldıgımız enlem ve boylama gore cubuk gosteriyoruz
            //bu işlemleri zaten mapVc de yaptıgım icin yazmadım
            let locationCoordinates = CLLocationCoordinate2D(latitude: Double(self.latitude)!, longitude: Double(self.longitude )!)
            let locationSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: locationCoordinates, span: locationSpan)
            self.mapView.setRegion(region, animated: true)
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationCoordinates
            
            self.mapView.addAnnotation(annotation)
            
        })
                
        
        
        //internet kontrolu
        let reachability = Reachability()!
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }
}
