//
//  UserProfileVC.swift
//  LetgoClone
//
//  Created by MacBook  on 25.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SDWebImage //SDWebImage kutuphanesini cocoapods ile kurduk bu kutuphane firebasedeki fotolari indirmemizi ve projemizde kullanmamizi saglar
import FacebookLogin
import Reachability



class UserProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //bu sayfamizda ust kismindaki profil bilgileri haric asagi kisimda da segment ile kontrol ettigimiz w ayri view bulunuyor
    //segmentler secildikce istenen bilesen gorunur olucak satilik urunler - begendiklerim(takip edilen urunler)
    
    @IBOutlet weak var collectionView: UICollectionView! //satilik urunler
    @IBOutlet weak var begendiklerim: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var settingsBtn: UIBarButtonItem!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var fullnameTxt: UILabel!
    @IBOutlet weak var konumTxt: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    
    //Cell'lere ekleyecegimiz fotolarin url'lerini bu dizide tutuyoruz
    var photoImageUrl = [String]()
    //Cell'lere ekleyecegimiz fotolarin url'lerini bu dizide tutuyoruz
    var userUid = [String]()
    var photoUidArray = [String]()
    
    
    
    //eger sosyal medya hesaplariyla giris yapilmissa sifre ve email degistir secenekleri cikmayacak
    var girisTypeIsSocial:Bool = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //bu metodla urunlerimizi geitiryotuz observer mantigindaki query tipini sectik (".value") oldugu icin firebase e bi veri eklenince oto refresh olur
       fetchItems()
    
        segmentedControl.font(name: "Roboto", size: 14)
        
        
        //en basta sadece satin aldiklarim gorunur olucak yani collectionView
        self.begendiklerim.isHidden = true 
        
        //collectionview delegate ve datasource bagliyoruz
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Profil resmi ayarları
        
        
        profilePicture.layer.cornerRadius = 5
        profilePicture.layer.masksToBounds = true
        
        //kullanici bilgilerii getiriyoruz
        fetchUserInformations()
       
        //text ler uzun gelirse sigmalari icin sizeToFit ekledik
        self.fullnameTxt.sizeToFit()
        self.konumTxt.sizeToFit()
        
      
      
        
    }
 

    
    
    func fetchUserInformations(){
        //kullanici bilgilerini aliyoruz firebase den
        FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).observe(.value, with: { (snapshot) in
            
            
            let snapshot = snapshot.value as! NSDictionary
            
            fullname = snapshot["fullName"] as! String
            self.fullnameTxt.text = snapshot["fullName"] as? String
            
            
            if let sehirim = snapshot["konum"] as? String {
                self.konumTxt.text = sehirim
                sehir = sehirim
            }
            
            if let enlemim = snapshot["enlem"] as? String {
                enlem = enlemim
            }
            
            if let boylamim = snapshot["boylam"] as? String {
                boylam = boylamim
            }
            
            
            
            if let profilPicture = snapshot["profilfoto"]{
                
                self.profilePicture.sd_setImage(with: URL(string: profilPicture as! String), placeholderImage: UIImage(named: "foto"))
                
            }
            
            if snapshot["girisType"] != nil{
                
                self.girisTypeIsSocial = true
            }
            
            
        })
        
    }
    
    
    //firebase den urunleri yukluyoruz
    @objc func fetchItems(){
        
        self.loading.startAnimating()
        
        self.collectionView.isHidden = false
        self.begendiklerim.isHidden = true
        
        
        FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).observe(.value, with: { (snapshot) in
            
            self.loading.startAnimating()
            
            self.photoUidArray.removeAll(keepingCapacity: false)
            self.photoImageUrl.removeAll(keepingCapacity: false)
            self.userUid.removeAll(keepingCapacity: false)
            
            var dataSnap:DataSnapshot!
            
            for questionChild in snapshot.children {
                
                
                dataSnap = questionChild as? DataSnapshot
                let value = dataSnap.value as! NSDictionary
                
                let baslik = value["baslik"] as? String
                
                
                if baslik != nil {
                    
                    //urunun anafotusunu aldik bunun karsiligi o fotunun url sidir ve bunu photoImageUrl dizimize ekleidk
                    if let picture = value["anafoto"]{
                        
                        self.photoUidArray.append(dataSnap.key)
                        self.userUid.append(FirebaseVariables.uid)
                        self.photoImageUrl.append(picture as! String)
                     
                    }
                    
                    
                }
                
                DispatchQueue.main.async {
                    
                self.collectionView.reloadData()
                }
            }
            
            
            
            self.loading.stopAnimating()
        }) { (error) in
            
            
            self.showAlert(title: "Hata", message: error.localizedDescription)
        }
        
        
        DispatchQueue.main.async {
        self.collectionView.reloadData()
        }
    }
    
    
    
    //COLLECTIONVIEW METODLARI
    
    // cell sayisi
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoImageUrl.count
    }
    
    // cell yapilandirilmasi yani cell'ler hangi cell'e bagli oldugunu storyboardda verdigimiz id "Cell" ile belli ediyoruz
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // cell'in bir ProfileCell turunde oldugunu belirtiyoruz
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ProfileCell
        
        //burada photoImageUrl dizimizde bi fotoUrl si varsa cell e fotomuzu ekliycez
        if(photoImageUrl.count>0){
            
                //helperFunc a ekledigimiz verifyUrl ile link'in geçerli bi url olup olm kontrol ediyoruz
                let test = self.verifyUrl(urlString: photoImageUrl[indexPath.row])
                if test {
                    
                    //ve daha sonra ekledigimiz sdImage kutuphanesi metoduyla url deki fotoyu indirip cell'in imageView'ina veriyoruz
                    cell.itemImage.sd_setImage(with: URL(string: self.photoImageUrl[indexPath.row]), placeholderImage: UIImage(named: "foto"))
                    
                }else{
                    
                    self.showAlert(title: "Hata", message: "fotoğraf yüklenirken bir sorun oluştu")
                    
                    
                }
            }
       
        
        
       
        cell.itemImage.layer.cornerRadius = 8.0
        cell.itemImage.clipsToBounds = true
        
        return cell
        
        
        
    }
    
    //burada her collectionView cell icin deger veriyoruz her satirda 3 cell olsun istiyoruz bunu da hesaplayip ekledik
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let cellWidth = (width - 30) / 3 // ekranın her satirinda 3 tane urun olmasi icin collecitonview cellerimizi 3 e boluyoruz boylece 3er tane ekleidk
        return CGSize(width: cellWidth, height: cellWidth )
    }
    
    
    
    //urunler yani collectionview celleri secilince cagilasan metod
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //hangi urun secildikse o urunun ve kullanicinin (bizim) id mizi dizilere ekliyoruz
        //bu degerleri postVC de kullanicaz
        postPhotoUid.append(photoUidArray[indexPath.row])
        postUserUid.append(userUid[indexPath.row])
        
        
        //postvc sayfamizi aciyoruz
        let post = self.storyboard?.instantiateViewController(withIdentifier: "PostVC") as! PostVC
        self.navigationController?.pushViewController(post, animated: true)
    }
    
    
    //segment secme metodu
    //hangi segment in secili oldugunu kontrol ediyoruz ona gore digerleini gizliyoruz
    @IBAction func segmentAction(_ sender: UISegmentedControl) {
        
        
        
        if(sender.selectedSegmentIndex == 0)
        {
            UIView.animate(withDuration: 0.2, animations: {
                
                self.collectionView.isHidden = false
                self.begendiklerim.isHidden = true
            })
        }
        else if(sender.selectedSegmentIndex == 1)
        {
            UIView.animate(withDuration: 0.2, animations: {
                
                self.collectionView.isHidden = true
                self.begendiklerim.isHidden = false
                
            })
        }
        
    }
    

    
   
    //ayarlar menusu burada eger sosyal medya hesaplariyla girissek sadece bilgileri duzenle ve
    //cikis yap secenegi olucak yoksa email ve sifre duzenle secenegi de olucak
    @IBAction func settingsBtn_action(_ sender: Any) {
        
        
        var actions: [(String, UIAlertActionStyle)] = []
        
        if girisTypeIsSocial {
            
            actions.append(("Bilgilerimi Düzenle", UIAlertActionStyle.default))
            actions.append(("Çıkış Yap", UIAlertActionStyle.destructive))
            actions.append(("Vazgeç", UIAlertActionStyle.cancel))
            
            
        }else {
        
        actions.append(("Bilgilerimi Düzenle", UIAlertActionStyle.default))
        actions.append(("Email adresini değiştir", UIAlertActionStyle.default))
        actions.append(("Şifreni değiştir", UIAlertActionStyle.default))
        actions.append(("Çıkış Yap", UIAlertActionStyle.destructive))
        actions.append(("Vazgeç", UIAlertActionStyle.cancel))
        
        }
        
        
        //self = ViewController
        self.showActionsheet(viewController: self, title: "Seçenekler", message: "", actions: actions) { (index) in
            
            if (index == 0){
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let editVC = storyboard.instantiateViewController(withIdentifier: "editProfile") as! EditProfileVC
               
                self.navigationController?.pushViewController(editVC, animated: true)
               
            }else if (index == 1){
                
                if !self.girisTypeIsSocial {
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let updateMail = storyboard.instantiateViewController(withIdentifier: "updateMail") as! EmailUpdateVC
                
                self.navigationController?.pushViewController(updateMail, animated: true)
                
                }else{
                    
                    do {
                        try Auth.auth().signOut()
                    } catch let signOutError as NSError {
                        print ("hata oluştu", signOutError)
                    }
                    
                    
                    sehir = ""
                    enlem = ""
                    boylam = ""
                    fullname = ""
                    
                    //cikis yapinca userDefault dan email siliyoruz ki uygulamayi acinca artık bu kullanici sayfasi tekraracilmasin
                    UserDefaults.standard.removeObject(forKey: "email")
                    UserDefaults.standard.removeObject(forKey: "password")
                    
                    let loginManager = LoginManager()
                    loginManager.logOut()
                    
                    UserDefaults.standard.synchronize()
                    
                    
                    
                    //appdelegate den giris sayfamizi cagiriyoruz
                    let signin = self.storyboard?.instantiateViewController(withIdentifier: "signInVC") as! SignInVC
                    let appDelegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.window?.rootViewController = signin
                    
                }
                
                
                
                
            }else if (index == 2){
                
                
                 if !self.girisTypeIsSocial {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let updatePassword = storyboard.instantiateViewController(withIdentifier: "updatePassword") as! PasswordUpdateVC
                
                self.navigationController?.pushViewController(updatePassword, animated: true)
                }
                
            }else if (index == 3){
                
                
                do {
                    try Auth.auth().signOut()
                } catch let signOutError as NSError {
                    print ("hata oluştu", signOutError)
                }
                
                
                sehir = ""
                enlem = ""
                boylam = ""
                fullname = ""
                
                //cikis yapinca userDefault dan email siliyoruz ki uygulamayi acinca artık bu kullanici sayfasi tekraracilmasin
                UserDefaults.standard.removeObject(forKey: "email")
                UserDefaults.standard.removeObject(forKey: "password")
                
                let loginManager = LoginManager()
                loginManager.logOut()
                
                UserDefaults.standard.synchronize()
                
                
                
                //appdelegate den giris sayfamizi cagiriyoruz
                let signin = self.storyboard?.instantiateViewController(withIdentifier: "signInVC") as! SignInVC
                let appDelegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.window?.rootViewController = signin
                
            }
        
        
            
        }
        
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
    
}


