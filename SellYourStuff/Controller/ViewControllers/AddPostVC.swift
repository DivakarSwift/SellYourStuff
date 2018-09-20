//
//  AddPostVC.swift
//  LetgoClone
//
//  Created by MacBook  on 25.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import Reachability


//3 adet global degisken tanimladik bircok yerde kullanacagimiz icin bu sekilde kullandik
var sehir = String()
var enlem = String()
var boylam = String()

//imagepicker, tabbar ... sinifimizdan türettik
class AddPostVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource,UITabBarControllerDelegate, UITextViewDelegate, UITextFieldDelegate  {
    
    //urun kategorisi
    var kategoriDizi = ["telefon","ev eşyası","araba","ev","yedek parça","diğer"]
    
    
    //sectigimiz kategoriyi tutmak icin bu degisken kullaniyoruz default olarak telefon gelir en başta
    var secilenKategori = "telefon"
    
    
    //scrollview ilk haline getirmek icin ilk degerleirni tutariz
    var firstw:CGFloat!
    var firsth:CGFloat!
    var firstx:CGFloat!
    var firsty:CGFloat!
    
    //eklenen fotolari tutmak icin images adli dizimizi olusturduk
    var images = [UIImage]()
    
    //foto secme, secerken kamera mi galeri mi gibi islemleri imagePicker sayesinde yapiyoruz
    var imagePicker = UIImagePickerController()

    //outlets - tasarim ekranindaki bilesenleri - action
    @IBOutlet weak var fiyatText: UITextField!
    @IBOutlet weak var urunBaslikTxt: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var yayinlaBtnOutlet: UIBarButtonItem!
    @IBOutlet weak var KategoriPickerView: UIPickerView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var aciklamaTextView: UITextView!
    @IBOutlet weak var fotoEkleBtn: UIButton!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    @IBOutlet weak var konum: UILabel!
    
    
    //uniq id ile fotolarimizi firebase e kaydederken her seferinde farklil bir isim olmasi icin
    //simdilik bos viewdidload da initilize ediyoruz
    var uniqeId = ""
    var fotoSirasi = 0 //eger birden fazla foto eklediysek firebase deki hiyerarsisine 1,2,3.. bu sekilde bi siralama mantigi olustuuroyruz
    
    //firebase depolama referansi bunun ile fotolari kaydediyoruz
    let storageRef =  Storage.storage().reference()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fiyatText.delegate = self
        
        
        self.tabBarController?.delegate = self
        
        
        
        //image'ı radius degerini eninin yarisina eşitledik bu da oval yapmak demektir (kare yi daire - dikdortgeni elips yapar)
        
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.clipsToBounds = true
     
        //scrollview ilk haline getirmek icin x y width ve height degerleri tutuyoruz
         firstw = scrollView.frame.width
         firsth = scrollView.frame.height
         firstx = scrollView.frame.origin.x
         firsty = scrollView.frame.origin.y
        
    
        
        //delegate ve data source baglıyoruz
        KategoriPickerView.delegate = self
        KategoriPickerView.dataSource = self
        
  
       
        // ekranda biryere dokununca klavyemizi kaybediyoruz recogniser ile
        let hideTap = UITapGestureRecognizer(target: self, action: #selector(AddPostVC.hideKeyboardTap))
        hideTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(hideTap)
        
        // imageview a dokununca foto yuklicek bunun icin selectImage metodunu cagiriyoruz
        let picTap = UITapGestureRecognizer(target: self, action: #selector(AddPostVC.selectImg))
        picTap.numberOfTapsRequired = 1
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(picTap)
        
        konum.sizeToFit()
        
        uniqeId = FirebaseVariables.ref.child("posts").childByAutoId().key
        
        //eger uygulama arkadaplana duserse calisan method
        NotificationCenter.default.addObserver(self, selector: #selector(AddPostVC.willResignActive), name: .UIApplicationWillResignActive, object: nil)
        
        
        
      
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        if sehir != "" {
            konum.text = sehir
        }else {
            konum.text = ""
        }
        
        
        //internet kontrolu
        let reachability = Reachability()!
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }
   
    
    // viewDidload da cagirdigimiz metod
    @objc func hideKeyboardTap() {
        self.view.endEditing(true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let s = NSString(string: fiyatText.text ?? "").replacingCharacters(in: range, with: string)
        guard !s.isEmpty else { return true }
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        return numberFormatter.number(from: s)?.intValue != nil
    }
    
    
    //eger bi foto eklenip islem tamamlanmadan uygulama arkaplana duserse yarida kalan urun silinir
    @objc func willResignActive(_ notification: Notification){
        
      FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).removeValue()
        refreshView()
        
    }
    
    
    //eger bi foto eklenip islem tamamlanmadan kullanici baska sayfaya gecerse yarida kalan urun silinir
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
      
        
        if let tabItems = self.tabBarController?.tabBar.items as NSArray?
        {
            
            // In this case we want to modify the badge number of the third tab:
            let tabItem = tabItems[1] as! UITabBarItem
            tabItem.isEnabled = false
       
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).removeValue()
        refreshView()
        
        UIApplication.shared.endIgnoringInteractionEvents()
        
        tabItem.isEnabled = true
         }
        
    }
    
    // viewDidload da cagirdigimiz metod
    // burada asagidaki imagePickerController metodunu cagiriyoruz
    //kullanici burada fotoyu kamera ile mi yoksa galeri den mi secicek onu seciyoruz
    @objc func selectImg() {
        
        
        let actionSheet = UIAlertController(title:"Profil Resmi", message:"Profil Resminizi Seçiniz", preferredStyle:.actionSheet)
        
        
        self.imagePicker.delegate = self
        
        //urunun galeriden secilmesi secenegi
        let gallery = UIAlertAction(title: "Resimler", style: .default) { (action) in
            
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.savedPhotosAlbum)
            {
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated:true, completion:nil)
            }
        }
        
        //urunun kameradan secilmesi secenegi
        let camera = UIAlertAction(title: "Kamera", style: .default) { (action) in
            
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
            {
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated:true, completion:nil)
            }
        }
        
        actionSheet.addAction(gallery)
        actionSheet.addAction(camera)
        
        actionSheet.addAction(UIAlertAction(title:"İptal", style:.cancel, handler:nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    
    // secilen fotoyu imageview yukler ve foto secim ekranini kapatir
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        imageView.image = info[UIImagePickerControllerEditedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
        
        // publish btn foto sectimizden aktif yaptik
        yayinlaBtnOutlet.isEnabled = true
        
       
        
        
        images.append(imageView.image!)
        
        
        //secilen fotolari scrollview a ekliyoruz
        for i in 0..<images.count {
            
            let imageView = UIImageView()
           
            let x = (self.view.frame.size.width * CGFloat(i)) / 1.96
            imageView.frame = CGRect(x: x, y: 0, width: self.scrollView.frame.width, height: self.scrollView.frame.height)
            imageView.contentMode = .scaleAspectFit
            imageView.image = images[i]
            
            scrollView.contentSize.width = (scrollView.frame.size.width * CGFloat(i + 1)) / 1.2
            scrollView.addSubview(imageView)
            
            
        }
        
        //ve eklenen fotoyu firebase e kaydediyoruz
        savePhoto()
        
    }
    
    //bir fotoyu firebase e kaydeden metod
    func savePhoto(){
        
        
        loading.startAnimating()
        self.yayinlaBtnOutlet.isEnabled = false
        let uniqeId2 = FirebaseVariables.ref.child("posts").childByAutoId().key
        let pictureStorageRef = FirebaseVariables.storageRef.child("user_profiles/\(FirebaseVariables.uid)/media/\(uniqeId2)/\(uniqeId)")
        
        
        //firebase storage e kaydediyoruz
        let lowResImageData = UIImageJPEGRepresentation(self.images.last!, 0.20)
        _ = pictureStorageRef.putData(lowResImageData!, metadata: nil)
        {metadata, error in
            if (error == nil){
                
                //storage ye kaydettikten sonra url ini de firebase database ye ekliyoruz
                pictureStorageRef.downloadURL(completion: { (url, error) in
                    if error != nil {
                        return
                    }
                    if url != nil {
                        
                        let childUpdates = ["/posts/\(FirebaseVariables.uid)/\(self.uniqeId)/fotolar/\(String(self.fotoSirasi+1))/picture":url!.absoluteString,
                                            "/posts/\(FirebaseVariables.uid)/\(self.uniqeId)/anafoto/":url!.absoluteString ] as [String : Any]
                        
                        FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(self.uniqeId).child("eklenmeTarihi").setValue(Date().timeIntervalSince1970)
                        
                        FirebaseVariables.ref.updateChildValues(childUpdates)
                        
                        self.fotoSirasi += 1
                        
                        
                        self.yayinlaBtnOutlet.isEnabled = true
                        self.loading.stopAnimating()
                        
                    }
                })
            }
        }
        
    }
    
    
    
    
    //PICKERVIEW METODLARI
    
    //numberOfRowsInComponent metodunda pickerimizda kac sutun olacagını beliryoruz (mesela dogum tarihinde 3 yaparız gun ay yıl)
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //numberOfRowsInComponent metodunda pickerimizda kac tane elemanımız olacagını belirtiyoruz
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return kategoriDizi.count
    }
    
    
    //bu metod ile picker elemanlarına isimlerini vericez bunuda string kategori dizimizden alıcaz
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return kategoriDizi[row]
        
    }
    
    //burada picker ın herhangi bir elemanı secilince calısan fonksiyon (burada bileseni secilince calısan fonksiyon)
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        secilenKategori = kategoriDizi[row]
        
    }
    
    @IBAction func fotoEkle_Action(_ sender: Any) {
        selectImg()
    }
    
    @IBAction func yayinlaBtn(_ sender: Any) {
        
    
        
        //sadece foto  baslik ve fiyat zorunlu alanlar
        if(urunBaslikTxt.text == "" || images.count == 0){
            
            self.showAlert(title: "Hata", message: "Foto ekleme ve ürün başlık kısımlarını lütfen eksiksiz doldurun")
            return
        }
        
        if(fiyatText.text == ""){
            self.showAlert(title: "Hata", message: "Fiyat giriniz")
            return
            
        }
        
        if(sehir == "" || enlem == "" || boylam == ""){
            
            
            self.showAlert(title: "Hata", message: "Lutfen isletmenizin adresini haritadan seciniz")
            return
        }
        
        
        verileriKaydet()
     
        
        
        
    }
  
   
    
    
    //ekle butonundan cagirilir ve girilen veirleri firebase e kaydeder
    func verileriKaydet() {
        
        self.loading.startAnimating()
        
        
        
      FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).child("baslik").setValue(self.urunBaslikTxt.text!)
                                
      FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).child("aciklama").setValue(self.aciklamaTextView.text)
        
      FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).child("photoId").setValue(uniqeId)
        
        FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).child("userUid").setValue(FirebaseVariables.uid)
                                
                            if self.fiyatText.text != "" {
                                    
                                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).child("fiyat").setValue(self.fiyatText.text)
                                }
                                
                                if self.secilenKategori != "" {
                                    
                                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).child("kategori").setValue(self.secilenKategori)
                                }
                                
                                if sehir != "" {
                                    
                                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).child("sehir").setValue(sehir)
                                }
                                
                                if enlem != "" {
                                    
                                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).child("enlem").setValue(enlem)
                                }
                                
                                if boylam != "" {
                                    
                                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).child("boylam").setValue(boylam)
                                }
                                
                                if fullname != "" {
                                    
                                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(uniqeId).child("fullName").setValue(fullname)
                                }
        
        
        
                            refreshView()
        
        
                        self.loading.stopAnimating()
                        uniqeId = FirebaseVariables.ref.child("posts").childByAutoId().key
        
                          
   
        
    }
    
    //urun eklendikten sonra viewlari i yeniler 
    func refreshView(){
        
        let subViews = self.scrollView.subviews
        for subview in subViews{
            subview.removeFromSuperview()
        }
        
        self.scrollView.frame = CGRect(x: firstx, y: firsty, width: firstw, height: firsth)
        
        imageView.image = UIImage(named: "camera-icon.JPG")
        
        urunBaslikTxt.text = ""
        aciklamaTextView.text = ""
        fiyatText.text = ""
        images.removeAll(keepingCapacity: false)
    }
   
    
    
}
