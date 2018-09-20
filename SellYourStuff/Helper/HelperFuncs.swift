

import Foundation
import UIKit
import MapKit
import FirebaseDatabase
import SwiftyJSON
import Chatto
import ChattoAdditions
import  Kingfisher
import Reachability

//Alert Uyari ekranini ekliyoruz

extension UIViewController:  CLLocationManagerDelegate, MKMapViewDelegate  {
    
    func showAlert(title: String, message: String, handler: ((UIAlertAction) -> Swift.Void)? = nil) {
        DispatchQueue.main.async { [unowned self] in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handler))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
     func showActionsheet(viewController: UIViewController, title: String, message: String, actions: [(String, UIAlertActionStyle)], completion: @escaping (_ index: Int) -> Void) {
        let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for (index, (title, style)) in actions.enumerated() {
            let alertAction = UIAlertAction(title: title, style: style) { (_) in
                completion(index)
            }
            alertViewController.addAction(alertAction)
        }
        viewController.present(alertViewController, animated: true, completion: nil)
    }
    
     func verifyUrl (urlString: String?) -> Bool {
        //Check for nil
        if let urlString = urlString {
            // create NSURL instance
            if let url = URL(string: urlString) {
                // check if your application can open the NSURL instance
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
    
    //internet kontrolu
    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! Reachability
        
        switch reachability.connection {
        case .wifi:
            print("Reachable via WiFi")
        case .cellular:
            print("Reachable via Cellular")
        case .none:
            self.showAlert(title: "", message: "İnternet bağlantınızı kontrol edip tekrar giriniz") { (action) in
                exit(0)
            }
        }
    }
    
    
    
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        
        annotationView.pinTintColor = UIColor(red: 37.0 / 255.0, green: 79.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)
        
        
        return annotationView
    }
    
    //bu metodumuzu sn cinsindeki timeinterval i normal tarih cisnsine ceviyoruz string olarak
    func dateFormatter(timestamp: Double?) -> String? {
        
        if let timestamp = timestamp {
            let date = Date(timeIntervalSinceReferenceDate: timestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "tr_TR")
            let timeSinceDateInSeconds = Date().timeIntervalSince(date)
            let secondInDays: TimeInterval = 20*60*60 //eger ilk 20 saat ise mesaj saati az ise
            //mesaj saatini fazla ise mesaj günü 7 gunden fazla ise tarih gostericez
            if timeSinceDateInSeconds > 7 * secondInDays {
                dateFormatter.dateFormat = "MM/dd/yy"
            } else if timeSinceDateInSeconds > secondInDays {
                dateFormatter.dateFormat = "EEEE"
            } else {
                dateFormatter.dateFormat = "HH:mm"
            }
            return dateFormatter.string(from: date)
        } else {
            return nil
        }
        
    }
    
    
    
    //burada aldigi tarihe uygun olan urunleri donduruyoruz
    func fetchByDate(itemsArray:[NSDictionary]?, desiredTime:Double, city:String, completion: @escaping ([NSDictionary]?) -> Void) {
        
        
        var newArray = [NSDictionary]()
        
        if itemsArray == nil {
        FirebaseVariables.ref.child("posts").observeSingleEvent(of: .value, with: { (snapshot) in
            var dataSnap:DataSnapshot!
            var dataSnap2:DataSnapshot!
            var childFotoNesneleriDict:NSDictionary!
            
            for questionChild in snapshot.children {
                dataSnap2 = questionChild as? DataSnapshot
                childFotoNesneleriDict = dataSnap2?.value as! NSDictionary
                
                for questionChild2 in dataSnap2.children {
                    dataSnap = questionChild2 as? DataSnapshot
                    let value = dataSnap.value as! NSDictionary
                    
                    let sehirim = value["sehir"] as? String
                    
                    let eklenmeTarihi = value["eklenmeTarihi"] as! Double
                 
                    
                    if  dataSnap2.key != FirebaseVariables.uid && eklenmeTarihi > desiredTime && sehirim == city{
                       
                        newArray.append(value)
                    }
                    
                }
               
            }
            
            if !newArray.isEmpty{
                
                completion(newArray)
            }else{
                
                completion(nil)
            }
        })
      
        }else{
            
            for item in itemsArray! {
                
                let eklenmeTarihi = item["eklenmeTarihi"] as! Double
                
                if eklenmeTarihi > desiredTime {
                    
                    newArray.append(item)
                }
                
            }
            
            if !newArray.isEmpty{
                
                completion(newArray)
            }else{
                
                completion(nil)
            }
            
        }
    }
    
    //burada aldigi kategoriye uygun olan urunleri donduruyoruz
    func fetchByCategory(itemsArray:[NSDictionary]?, category:String, city:String, completion: @escaping ([NSDictionary]?) -> Void){
        
        
        
        var newArray = [NSDictionary]()
        
        if itemsArray == nil {
            FirebaseVariables.ref.child("posts").observeSingleEvent(of: .value, with: { (snapshot) in
                var dataSnap:DataSnapshot!
                var dataSnap2:DataSnapshot!
                var childFotoNesneleriDict:NSDictionary!
                
                for questionChild in snapshot.children {
                    dataSnap2 = questionChild as? DataSnapshot
                    childFotoNesneleriDict = dataSnap2?.value as! NSDictionary
                    
                    for questionChild2 in dataSnap2.children {
                        dataSnap = questionChild2 as? DataSnapshot
                        let value = dataSnap.value as! NSDictionary
                        
                        let sehirim = value["sehir"] as? String
                        
                        let cate = value["kategori"] as! String
                        
                        
                        if  dataSnap2.key != FirebaseVariables.uid && cate == category && sehirim == city{
                            
                            newArray.append(value)
                        }
                        
                    }
                    
                }
                
                if !newArray.isEmpty{
                    
                    completion(newArray)
                }else{
                    
                    completion(nil)
                }
            })
            
        }else{
            
            for item in itemsArray! {
                
                let cate = item["kategori"] as! String
                
                if cate == category {
                    
                    newArray.append(item)
                }
                
            }
            
            if !newArray.isEmpty{
                
                completion(newArray)
            }else{
                
                completion(nil)
            }
            
        }
        
    }
    
    
    func fetchByPrice(itemsArray:[NSDictionary]?, city:String, sorting:Int, completion: @escaping ([NSDictionary]?) -> Void){ //eger sorting 1 ise artan, 2 ise azalan siralama
        
        var newArray = [NSDictionary]()
      
        
        if itemsArray == nil {
            print("****")
            FirebaseVariables.ref.child("posts").observeSingleEvent(of: .value, with: { (snapshot) in
                var dataSnap:DataSnapshot!
                var dataSnap2:DataSnapshot!
                var childFotoNesneleriDict:NSDictionary!
                
                
                for questionChild in snapshot.children {
                    dataSnap2 = questionChild as? DataSnapshot
                    childFotoNesneleriDict = dataSnap2?.value as! NSDictionary
                    
                    for questionChild2 in dataSnap2.children {
                        dataSnap = questionChild2 as? DataSnapshot
                        let value = dataSnap.value as! NSDictionary
                        
                        let sehirim = value["sehir"] as? String
                        
                        
                        
                        if  dataSnap2.key != FirebaseVariables.uid  && sehirim == city{
                            
                            newArray.append(value)
                        }
                        
                    }
                    
                    if sorting == 1 {
                        
                        
                        newArray = newArray.sorted {
                            (dictOne, dictTwo) -> Bool in
                            return dictTwo["fiyat"]! as! String > dictOne["fiyat"]! as! String
                            }
                        
                    }else{
                        
                        
                        newArray = newArray.sorted {
                            (dictOne, dictTwo) -> Bool in
                            return dictOne["fiyat"]! as! String > dictTwo["fiyat"]! as! String
                            }
                        
                    }
                    
                }
                
                if !newArray.isEmpty{
                    completion(newArray)
                }else{
                    
                    completion(nil)
                }
            })
            
        }else{
                if sorting == 1 {
                    
                    
                    newArray = itemsArray!.sorted {
                        (dictOne, dictTwo) -> Bool in
                        
                        return dictTwo["fiyat"]! as! String > dictOne["fiyat"]! as! String
                        }
                    
                }else{
                    
                    newArray = itemsArray!.sorted {
                        (dictOne, dictTwo) -> Bool in
                        
                        
                        return dictOne["fiyat"]! as! String > dictTwo["fiyat"]! as! String
                        }
                    
                }
                
            
            
            if !newArray.isEmpty{
                
                completion(newArray)
            }else{
                
                completion(nil)
            }
            
        }
    }
    
    
    
    
}

//segment font ve size ayarlamak icin
extension UISegmentedControl {
    func font(name:String?, size:CGFloat?) {
        let attributedSegmentFont = NSDictionary(object: UIFont(name: name!, size: size!)!, forKey: NSAttributedStringKey.font as NSCopying)
        
        
        setTitleTextAttributes(attributedSegmentFont as [NSObject : AnyObject], for: .normal)
    }
}


extension NSObject {
    
    //burada firebase den aldıgımız json mesaji ChatItemProtocol a ceviriyoruz
    func convertToChatItemProtocol(messages: [JSON]) -> [ChatItemProtocol] {
        var convertedMessages = [ChatItemProtocol]()
        
        convertedMessages = messages.map({ (message) -> ChatItemProtocol in
            let senderId = message["senderId"].stringValue
            let model = MessageModel(uid: message["uid"].stringValue, senderId: senderId, type: message["type"].stringValue, isIncoming: senderId == FirebaseVariables.uid ? false : true, date: Date(timeIntervalSinceReferenceDate: message["date"].doubleValue), status: message["status"] == "success" ? MessageStatus.success : MessageStatus.sending)
            if message["type"].stringValue == TextModel.chatItemType {
                let textMessage = TextModel(messageModel: model, text: message["text"].stringValue)
                return textMessage
            } else {
                
                let loading = #imageLiteral(resourceName: "loading")
                let photoMessage = PhotoModel(messageModel: model, imageSize: loading.size, image: loading)
                return photoMessage
            }
            
        })
        return convertedMessages
    }
    
    //burada foto indirilir
    func parseURLs(UID_URL: (key: String, value: String)) {
        let uid = UID_URL.key
        let imageURL = UID_URL.value
        KingfisherManager.shared.retrieveImage(with: URL(string: imageURL)!, options: nil, progressBlock: nil) { (image, _, _, _) in
            if let image = image {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateImage"), object: nil, userInfo: ["image": image, "uid": uid])
            }
        }
    }
    
    
}

extension Array {
    
    func canSupport(index: Int ) -> Bool {
        return index >= startIndex && index < endIndex
    }
}




