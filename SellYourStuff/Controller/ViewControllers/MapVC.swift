//
//  MapVC.swift
//  LetgoClone
//
//  Created by MacBook  on 26.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import MapKit
import Reachability

//Urun Ekleme ve ilk kayit olurken ki konum secmemnin ortak map ekrani


//eger true ise ona gore farkli islemler yapicak, anasayfayi acicak
//false ise urun eklerken acilmis oldugunu anlariz
var isComingForUsers:Bool = false

var email =  ""
var password =  ""
var fullname =  ""

class MapVC: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
  
    
    //bu degiskenlerde secilen enlem ve boylam tutcaz firebase kaydetmek için
    var selectedLatitude = ""
    var selectedLongitude = ""
    

    
    
    //eger signUp dan geliyorsak true olucak ve ona gore farkli islemler yapicak, anasayfayi acicak
    //false ise urun eklerken acilmis oldugunu anlariz
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        selectedLatitude = "" //her calıstıgında secilen enlem boylamı sıfırlıyoruz eskisiyle bir sıkıntı olmasın diye
        selectedLongitude = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //internet kontrolu
        let reachability = Reachability()!
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }
    
  
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sehir = ""
        enlem = ""
        boylam = ""
        
        mapView.delegate = self
        
       
        
        //burada haritada uzun basma olayını ekliyoruz bunu eklememizin nedeni secilen alanda cubuk olusturmak
        let lpgRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapVC.selectLocation(gestureRecogniser:)))
        lpgRecogniser.minimumPressDuration = 0.3 //basılı tutma olayının suresini ekledik
        mapView.addGestureRecognizer(lpgRecogniser)
        
        
      
        
        
        
    }
    
    //konum secilince calisan metod yani haritada bi alana dokununca
    @objc func selectLocation(gestureRecogniser: UIGestureRecognizer ){
        
        if gestureRecogniser.state == UIGestureRecognizerState.began{
            
            let touches = gestureRecogniser.location(in: self.mapView)
            let coordinates = self.mapView.convert(touches, toCoordinateFrom: self.mapView)
            
            //işte burada uzun tıklamayla secilen alanda cıkan cubugu olusturuyoruz
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            //annotation.title = globalLocationName //bir onceki sayfada olusturdugumuz ismi simdi burada ekliyoruz
           // annotation.subtitle = globalLocationType
            self.mapView.addAnnotation(annotation)
            self.selectedLatitude = String(coordinates.latitude)
            self.selectedLongitude = String(coordinates.longitude)
            enlem = String(coordinates.latitude)
            boylam = String(coordinates.longitude)
            
            
            let geoCoder = CLGeocoder()
            let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            
            geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
                
                // Place details
                var placeMark: CLPlacemark!
                placeMark = placemarks?[0]

                // sehrimizi seciyoruz
                if let konumSehir = placeMark.subAdministrativeArea {
                    sehir = konumSehir
                    
                }
                
                
            }
          }
        //ve haritaya ekledigimiz dokunma olayını kaldioruz
        if gestureRecogniser.state == UIGestureRecognizerState.ended {
            self.mapView.removeGestureRecognizer(gestureRecogniser)
        }
        
    }
    
    //sectigimiz konuma dokunca calisan metod bu konumu silebilirz
    //farki bie konum secmek icin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        
        var actions: [(String, UIAlertActionStyle)] = []
        actions.append(("Konumu Sil", UIAlertActionStyle.destructive))
        actions.append(("Vazgeç", UIAlertActionStyle.cancel))
        
        //self = ViewController
       self.showActionsheet(viewController: self, title: "Seçenekler", message: "General Message in Action Sheet", actions: actions) { (index) in
            
            if (index == 0){
                
                sehir = ""
                enlem = ""
                boylam = ""
                
                mapView.removeAnnotation(view.annotation!)
                
                //burada haritada uzun basma olayını ekliyoruz bunu eklememizin nedeni secilen alanda cubuk olusturmak
                let lpgRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapVC.selectLocation(gestureRecogniser:)))
                lpgRecogniser.minimumPressDuration = 0.3 //basılı tutma olayının suresini ekledik
                mapView.addGestureRecognizer(lpgRecogniser)
            }else{
                
            }
        }
        
    }
    
   
    
    @IBAction func kaydetBtn_action(_ sender: Any) {
        
        if (!self.mapView.gestureRecognizers!.isEmpty){
            
            self.showAlert(title: "", message: "konum secmediniz")
            return
        }
        
     
                self.dismiss(animated: true, completion: nil)
        
        
        if isComingForUsers {
            
             if(sehir != ""){
            
            FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("konum").setValue(sehir)
            FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("enlem").setValue(selectedLatitude)
            FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("boylam").setValue(selectedLongitude)
            
                
             }
                
            isComingForUsers = false
            
            
                
                // eger boyle bi kullanici varsa userdefault a kaydediyoruz
                UserDefaults.standard.set(email, forKey: "email")
                UserDefaults.standard.set(password, forKey: "password")
                UserDefaults.standard.synchronize()
                
                email = ""
                password = ""
                fullname = ""
                
                
                //ve appdelegate deki login() meotdu ile userdefault'da bir deger oldugundan (yukaridaki kod ile) anasayfaya gidiyoruz
                let appDelegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.loginAsUser()
                
           
            }
        
        }
    
    @IBAction func geriBtn_action(_ sender: Any) {
        
        
        email = ""
        password = ""
        fullname = ""
        self.dismiss(animated: true, completion: nil)
        
       
    }
    
  
}



