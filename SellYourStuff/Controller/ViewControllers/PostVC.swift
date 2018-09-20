//
//  PostVC.swift
//  LetgoClone
//
//  Created by MacBook  on 31.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON
import FirebaseStorage
import FirebaseAnalytics
import FirebaseDatabaseUI
import ImageSlideshow //İmageSlider kutuphanesini ekliyoruz
import FirebaseDatabase
import Reachability

//bir onceki sayfadan hangi post u seciyorsak onun uuid sini aliyoruz ve o postu getiyoruz
var postPhotoUid = [String]()
var postUserUid = [String]()

class PostVC: UIViewController {
    
    
    @IBOutlet weak var segmentOutlet: UISegmentedControl!
    @IBOutlet weak var urunAdiTxt: UILabel!
    @IBOutlet weak var firmaAdiTxt: UILabel!
    @IBOutlet weak var adresTxt: UILabel!
    @IBOutlet weak var mapContainer: UIView!
    @IBOutlet weak var fiyatLbl: UILabel!
    @IBOutlet weak var aciklamaTxt: UILabel!
    @IBOutlet weak var kategoriTxt: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var bilgilendirmeContainer: UIView!
    @IBOutlet weak var slideShow: ImageSlideshow!
    
    
    var isLiked:Bool = false
    
    //imageSlider a ekleyecegimiz fotolar burada tutulacak
    var inputs = [SDWebImageSource]()
    
    var postSahibiEmail:String = ""
    var mainPhotoUrl:String = ""
    
     let likeBtn = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        mainPhotoUrl = ""
        
        isLiked = false
       
        segmentOutlet.font(name: "Roboto", size: 14)
        
        // geri butonu
        self.navigationItem.hidesBackButton = true
        let backBtn = UIBarButtonItem(image: UIImage(named: "back.png"), style: .plain, target: self, action: #selector(PostVC.back(_:)))
        self.navigationItem.leftBarButtonItem = backBtn
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor(red: 37.0 / 255.0, green: 79.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)
        
        
        //eger post un sahibi biz isek sol ust butona ayarlar secenegi degilsek like butonunu ekledik
        if postUserUid.last! == FirebaseVariables.uid {
        
        // secenekler butonu
        self.navigationItem.hidesBackButton = true
        let optionsBtn = UIBarButtonItem(image: UIImage(named: "three-dots.png"), style: .plain, target: self, action: #selector(PostVC.showOptions(_:)))
        self.navigationItem.rightBarButtonItem = optionsBtn
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 37.0 / 255.0, green: 79.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)
        
        }else {
            
           
           //likeBtn.setImage(UIImage(named:"like-btn"), for: .normal)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: likeBtn)
            
            let btnTap = UITapGestureRecognizer(target: self, action: #selector(PostVC.likeImage))
            btnTap.numberOfTapsRequired = 1
            likeBtn.isUserInteractionEnabled = true
            likeBtn.addGestureRecognizer(btnTap)
            
        
        }
       
        
        
        // ekrani sağa kaydirirsak geldigimiz sayfaya geri doneriz
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(PostVC.back(_:)))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        //imageSliderimizi yapilandiriyoruz
        let pageIndicator = UIPageControl()
        pageIndicator.pageIndicatorTintColor = UIColor.white
        pageIndicator.currentPageIndicatorTintColor = UIColor.white
        slideShow.pageIndicator = pageIndicator
        
        
        slideShow.activityIndicator = DefaultActivityIndicator()
        
        //sliderimiza dokunma olayini ekledik dokunca slider acilir
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PostVC.didTap))
        slideShow.addGestureRecognizer(gestureRecognizer)
        
        
       
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //postvc de tabbari gizliyoruz
        self.tabBarController?.tabBar.isHidden = true
        
        //eger post sahibi biz degilsek sag alt a mesaj at butonunu ekliyoruz
        
        if postUserUid.last! != FirebaseVariables.uid {
        
        let mesajGonderBtn = UIButton()
        mesajGonderBtn.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y + view.frame.size.height - 50 , width: view.frame.width , height: 60)
        mesajGonderBtn.backgroundColor = UIColor(red: 37.0 / 255.0, green: 79.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)
        
        
        let img = UIImage(named: "mesaj-at")
        mesajGonderBtn.setImage(img , for: .normal)
        
        mesajGonderBtn.imageView?.contentMode = .scaleAspectFill
        
        //mesaj eklemeye basinca mesajGonderAction metodumuz tetiklerinir
        mesajGonderBtn.addTarget(self, action: #selector(mesajGonderAction), for: .touchUpInside)
        self.view.addSubview(mesajGonderBtn)
        
        }
        
        editPhotoUid = ""
        
        self.inputs.removeAll(keepingCapacity: true)
        
        self.mapContainer.isHidden = true
        
      
        
        //post a ait bilgileri cekiyoruz
        getInfo()
        
        //internet kontrolu
        let reachability = Reachability()!
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }
    
    
    //post sahibine mesaj atma metodunu ve mesaj ekranini geitiyoruz
    @objc func mesajGonderAction(sender: UIButton!) {
        
        addContact(email: postSahibiEmail)
        
        let reference = FirebaseVariables.ref.child("User-messages").child(FirebaseVariables.uid).child(postUserUid.last!).queryLimited(toLast: 51) //normalde ChatDataSourceProtocol da 50 mesaj olarak belirtmistik ancak bir burada 1 fazlasini belirtiyoruz bu 51. mesaj gozukmez ancak bunun nedeni eger bir daha load yani eski mesaj yuklersek
        //bu mesaj ve ustundeki yuklemeek icin adres belli eder
        
       
        
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            //burada snaphot da key-value olarak "User-messages" icinden mesajlarizi aldik ve tarihe gore sıraladık
            let messages = Array(JSON(snapshot.value as Any).dictionaryValue.values).sorted(by: { (lhs, rhs) -> Bool in
                
                return lhs["date"].doubleValue < rhs["date"].doubleValue
            })
            
            let converted = self?.convertToChatItemProtocol(messages: messages)
            //burada json olarak aldigimiz mesaji helper dosyasinda
            //olusturdumuz bi metodla ChatItemProtocol a ceviriyoruz
            
            let chatlog = ChatLogController()
            chatlog.userUID = postUserUid.last!
            chatlog.dataSource = DataSource(initialMessages: converted!, uid: postUserUid.last!)
            
            chatlog.messagesArray = FUIArray(query: FirebaseVariables.ref.child("User-messages").child(FirebaseVariables.uid).child(postUserUid.last!).queryStarting(atValue: nil, childKey: converted?.last?.uid), delegate: nil)
            
            self?.navigationController?.show(chatlog, sender: nil)
           
            //eger yuklenen mesajlar icinde foto varsa bunu helperdaki parseURLs() metodumuzla fotoya cevirip yukleriz
            
            messages.filter({ (message) -> Bool in
                return message["type"].stringValue == PhotoModel.chatItemType
            }).forEach({ (message) in
                
                
                self?.parseURLs(UID_URL: (key: message["uid"].stringValue, value: message["image"].stringValue))
            })
            
        })
        
    }
    
    //sayfayi kapatirken tabbari tekrar aktif yapiyoruz
    override func viewWillDisappear(_ animated: Bool) {
        
        self.tabBarController?.tabBar.isHidden = false
    }
    
    //imageslidera dokununca slider ekrani kaplar
    @objc func didTap() {
        slideShow.presentFullScreenController(from: self)
    }
    
    //foto begenme butonu
    @objc func likeImage() {
        likeBtn.setImage(UIImage(named:"three-dots"), for: .normal)
        
        if isLiked {
            self.likeBtn.setImage(UIImage(named:"like-btn"), for: .normal)
            isLiked = false
            FirebaseVariables.ref.child("liked").child(FirebaseVariables.uid).child(postPhotoUid.last!).removeValue()
           

        }else{
           FirebaseVariables.ref.child("liked").child(FirebaseVariables.uid).child(postPhotoUid.last!).child("owner").setValue(postUserUid.last!)
            
            FirebaseVariables.ref.child("liked").child(FirebaseVariables.uid).child(postPhotoUid.last!).child("anafoto").setValue(mainPhotoUrl)
            
            
            self.likeBtn.setImage(UIImage(named:"unlike-btn"), for: .normal)
            isLiked = true

            
        }
    }
    
    
    
    // geri butonuna basinca geldigimiz sayfaya donuyoruz
    @objc func back(_ sender: UIBarButtonItem) {
        
        
        // push back
        _ = self.navigationController?.popViewController(animated: true)
        
        // clean post uuid from last hold
        if !postPhotoUid.isEmpty {
            postPhotoUid.removeLast()
            postUserUid.removeLast()
        }
        
        
        
    }
    
    
    // options butonuna basinca düzenle ve post silme olaylarini ekliyoruz
    @objc func showOptions(_ sender: UIBarButtonItem) {
        
        var actions: [(String, UIAlertActionStyle)] = []
        actions.append(("Düzenle", UIAlertActionStyle.default))
        actions.append(("Postu sil", UIAlertActionStyle.default))
        actions.append(("Vazgeç", UIAlertActionStyle.cancel))
        
        //self = ViewController
        self.showActionsheet(viewController: self, title: "Seçenekler", message: "General Message in Action Sheet", actions: actions) { (index) in
            
            
            
            if (index == 0){
                // send post uuid to "postuuid" variable
                //postPhotoUid.append(photoUidArray[indexPath.row])
                //postUserUid.append(userUid[indexPath.row])
                
                editPhotoUid = postPhotoUid.last!
                
                
                // navigate to post view controller
                let UrunDuzenle = self.storyboard?.instantiateViewController(withIdentifier: "UrunDuzenle") as! EditPostVC
                
                self.navigationController?.pushViewController(UrunDuzenle, animated: true)
                
             
            }else if (index == 1){
               
               
                FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(postPhotoUid.last!).removeValue()
                
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
             
                
                
            }
        }
        
    }
    
    
    //post a ait bilgileri cekiyoruz
    func getInfo(){
        
        
        selectedLatitude = ""
        selectedLongitude = ""
        
        
    FirebaseVariables.ref.child("liked").child(FirebaseVariables.uid).child(postPhotoUid.last!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            
            self.isLiked = false
            self.likeBtn.setImage(UIImage(named:"like-btn"), for: .normal)
            
            let value = snapshot.value as? NSDictionary
            
            if let likedUid = value?["owner"] as? String {
                
                if likedUid == postUserUid.last {
                    
                    
                    
                   self.likeBtn.setImage(UIImage(named:"unlike-btn"), for: .normal)
                    
                    self.isLiked = true
                    
                }
                
            }
            
          
            })
        
        
        
        
        
        FirebaseVariables.ref.child("users").child(postUserUid.last!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            
            self.postSahibiEmail = value!["email"] as! String
         })
        
        FirebaseVariables.ref.child("posts").child(postUserUid.last!).child(postPhotoUid.last!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            
            selectedLongitude = value!["boylam"] as! String
            selectedLatitude = value!["enlem"] as! String
            
            self.urunAdiTxt.text = value!["baslik"] as? String
            self.firmaAdiTxt.text = value!["fullName"] as? String
            
            
            
            self.adresTxt.text = value!["sehir"] as? String
            self.fiyatLbl.text = value!["fiyat"] as? String
            
            if let aciklama = value!["aciklama"] as? String{
                self.aciklamaTxt.text = aciklama
            }
            
            if let anafoto = value!["anafoto"] as? String{
                self.mainPhotoUrl = anafoto
            }
            
            if let kategori = value!["kategori"] as? String{
                self.kategoriTxt.text = kategori
            }
            
            
            FirebaseVariables.ref.child("posts").child(postUserUid.last!).child(postPhotoUid.last!).child("fotolar").observeSingleEvent(of: .value, with: { (snapshot) in
                
                
                
                var dataSnap:DataSnapshot!
                var childFotoNesneleriDict:NSDictionary!
              
                
                for questionChild in snapshot.children {
                    dataSnap = questionChild as? DataSnapshot
                    childFotoNesneleriDict = dataSnap?.value as! NSDictionary
                    
                    
                    let fotoUrl = URL(string: childFotoNesneleriDict!["picture"] as! String)
                    
                    
                    self.inputs.append(SDWebImageSource(url: fotoUrl!))
                    self.slideShow.setImageInputs(self.inputs)
                    
                }
                
            
         
                
            })
        })
    }
    
    //segmentler arasi gecis
    @IBAction func segmentControl(_ sender: AnyObject) {
        
         UIView.animate(withDuration: 0.4, animations: {
        
            self.scrollView.contentOffset.y = self.segmentOutlet.frame.origin.y - 16
            
         })
        
        
        if(sender.selectedSegmentIndex == 0)
        {
            UIView.animate(withDuration: 0.2, animations: {
                
                self.mapContainer.isHidden = true
                self.bilgilendirmeContainer.isHidden = false
            })
        }
        else if(sender.selectedSegmentIndex == 1)
        {
            UIView.animate(withDuration: 0.2, animations: {
                
                self.mapContainer.isHidden = false
                self.bilgilendirmeContainer.isHidden = true
            })
        }
        
        
        
    }
    
    //mesaj at butonuna basinca urun sahibine mesja atmak icin messageViewController a yonlendiyoruz
    func addContact(email: String){
        
        var fullName = String()
        var keyy = ""
        var emaill = ""
        var profilfoto = ""
        var profilfotoBenim = ""
        var kull = ""
        
        
        FirebaseVariables.ref.child("users").observeSingleEvent(of: .value, with: {  [weak self] (snapshot) in
            let snapshot = JSON(snapshot.value as Any).dictionaryValue
            
            
            if snapshot.index(where: { (key, value) -> Bool in
                
                if (key == FirebaseVariables.uid){
                    fullName = value["fullName"].stringValue
                }
                
                if (key == FirebaseVariables.uid){
                    profilfotoBenim = value["profilfoto"].stringValue
                }
                
                if value["email"].stringValue == email {
                    
                    keyy = key
                    emaill = email
                    kull = value["fullName"].stringValue
                    profilfoto = value["profilfoto"].stringValue
                    
                }
                
                return fullName != "" && kull != ""
                
            }) != nil {
                
                if email == Auth.auth().currentUser?.email{
                    
                    self?.showAlert(title: "", message: "kendi email adresinizi giremezsin")
                    
                }else{
                    
                    let allUpdates =  ["/users/\(FirebaseVariables.uid)/Contacts/\(keyy)": (["email": emaill, "fullName": kull, "profilfoto": profilfoto]),
                                      
                                       "/users/\(keyy)/Contacts/\(FirebaseVariables.uid)": (["email": Auth.auth().currentUser!.email!, "fullName": fullName, "profilfoto": profilfotoBenim])]
                    
                    //yukarıda kullandıgımız display name' i signUp da kullanici adi olarak vermistik
                    FirebaseVariables.ref.updateChildValues(allUpdates)
                    
                  
                    
                }
            }else{
                
                self?.showAlert(title: "", message: "email bulunamadi")
            }
        })
        
    }
    
    
}
