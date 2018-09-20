//
//  EditPostVC.swift
//  LetgoClone
//
//  Created by MacBook  on 3.08.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import Reachability

//bir onceki sayfadan hangi post u seciyorsak onun uuid sini aliyoruz ki bulalim hemen
var editPhotoUid = String()


var selectedLatitude = ""
var selectedLongitude = ""

class EditPostVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource,UITextFieldDelegate  {
    
    //urun kategorisi
     var kategoriDizi = ["telefon","ev eşyası","araba","ev","yedek parça","diğer"]
    
    
    var secilenKategori = ""
    
    
    //scrollview ilk haline getirmek icin ilk degerleirni tutariz
    var firstw:CGFloat!
    var firsth:CGFloat!
    var firstx:CGFloat!
    var firsty:CGFloat!
    
    //photolarla ilgili bilgileri bu dizilerde tutuypruz
    var images = [UIImage]()
    var newImages = [UIImage?]() //yeni ekledigimiz fotolari burada tutuyoruz
    var imagesUrl = [String?]()
    
    let ref = Database.database().reference().child("posts")
    var handler:DatabaseHandle!
    
    
    @IBOutlet weak var yayinOutlet: UIBarButtonItem!
    @IBOutlet weak var konumDegistirBtn: UIButton!
    @IBOutlet weak var konumTxt: UILabel!
    @IBOutlet weak var fiyatText: UITextField!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var baslikTxt: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fotoEkleBtn: UIButton!
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    @IBOutlet weak var urunAciklamaTx: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fiyatText.delegate = self
        
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.clipsToBounds = true
        
        //scrollview ilk haline getirmek icin x y width ve height degerleri tutuyoruz
        firstw = scrollView.frame.width
        firsth = scrollView.frame.height
        firstx = scrollView.frame.origin.x
        firsty = scrollView.frame.origin.y
        
        
        
        
        //delegate ve data source baglıyoruz
        picker.delegate = self
        picker.dataSource = self
        
        
        
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
        
        konumTxt.sizeToFit()
        
        
        loading.startAnimating()
        
        //urun bilgilerini bu metod ile getiyoruz
        getInfo()
        
        //urun fotolarini bu metodla getiyoruz
        self.loadFromFireBase(completionHandler: { [weak self] success in
            if success {
                
                self?.bringPhotosToScrollView()
                self?.loading.stopAnimating()
                
            }
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        if sehir != "" {
            konumTxt.text = sehir
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
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let s = NSString(string: fiyatText.text ?? "").replacingCharacters(in: range, with: string)
        guard !s.isEmpty else { return true }
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        return numberFormatter.number(from: s)?.intValue != nil
    }
    
    func getInfo(){
        selectedLatitude = ""
        selectedLongitude = ""
        self.imagesUrl.removeAll(keepingCapacity: false)
        self.newImages.removeAll(keepingCapacity: false)
        self.images.removeAll(keepingCapacity: false)
        
        FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            
            
            selectedLongitude = value!["boylam"] as! String
            selectedLatitude = value!["enlem"] as! String
            
            self.baslikTxt.text = value!["baslik"] as? String
            self.konumTxt.text = value!["sehir"] as? String
            sehir = value!["sehir"] as! String
            enlem = value!["enlem"] as! String
            boylam = value!["boylam"] as! String
            self.fiyatText.text = value!["fiyat"] as? String
            
            if let aciklama = value!["aciklama"] as? String{
                self.urunAciklamaTx.text = aciklama
            }
            
            if let kategori = value!["kategori"] as? String{
                
                for (index, item) in self.kategoriDizi.enumerated() {
                    
                    if item == kategori {
                        self.picker.selectRow(index, inComponent: 0, animated: false)
                    }
                    
                }
                
            }
            
            
            
            
            
        })
    }
    
    
    func bringPhotosToScrollView(){
        
        let subViews = self.scrollView.subviews
        for subview in subViews{
            subview.removeFromSuperview()
        }
        
        self.scrollView.frame = CGRect(x: firstx, y: firsty, width: firstw, height: firsth)
        // images.removeAll(keepingCapacity: false)
        
       appendImages()
        
        imageView.image = nil
        
        if !images.isEmpty {
            
            imageView.image = images[0]
            
        }
    }
    
    
  
    
    func loadFromFireBase(completionHandler:@escaping (_ value: Bool)->()) {
        
        
        self.loading.startAnimating()
        
        
        FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(postPhotoUid.last!).child("fotolar").observeSingleEvent(of: .value, with: { (snapshot) in
            
            
            let fotoSayisi = snapshot.childrenCount
            
            var dataSnap:DataSnapshot!
            var childFotoNesneleriDict:NSDictionary!
            
            
            for questionChild in snapshot.children {
                dataSnap = questionChild as? DataSnapshot
                childFotoNesneleriDict = dataSnap?.value as! NSDictionary
                
                
                self.imageView.sd_setImage(with: URL(string: childFotoNesneleriDict!["picture"] as! String), placeholderImage: UIImage(named: "foto"))
                
                self.images.append(self.imageView.image!)
                self.newImages.append(nil)
                self.imagesUrl.append(childFotoNesneleriDict!["picture"] as? String)
                //}
                
                
                if self.images.count == fotoSayisi {
                    
                    completionHandler(true)
                }else{
                    
                    completionHandler(false)
                    
                }
            }
            
        })
        
        self.loading.stopAnimating()
        
    }
    
    
    // viewDidload da cagirdigimiz metod
    @objc func hideKeyboardTap() {
        self.view.endEditing(true)
    }
    
    
    // viewDidload da cagirdigimiz metod
    // burada asagidaki imagePickerController metodunu cagiriyoruz
    @objc func selectImg() {
        
        
        self.loading.startAnimating()
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    
    // secilen fotoyu imageview yukler ve foto secim ekranini kapatir
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        
        imageView.image = info[UIImagePickerControllerEditedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
        
        
        images.append(imageView.image!)
        newImages.append(imageView.image!)
        
         appendImages()
        
        var fotoSirasi:Int = 0
        DispatchQueue.main.async {
            
            self.loading.startAnimating()
           self.view.isUserInteractionEnabled = false
            FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).child("fotolar").observeSingleEvent(of: .value, with: { (snapshot) in
                
                
                var dataSnap:DataSnapshot!
                
                for questionChild in snapshot.children {
                    dataSnap = questionChild as? DataSnapshot
                    
                    fotoSirasi = Int(dataSnap.key)!
                }
                
                
            })
            
            let uniqeId = FirebaseVariables.ref.child("posts").childByAutoId().key
            let pictureStorageRef = FirebaseVariables
                .storageRef.child("user_profiles/\(FirebaseVariables.uid)/media/\(editPhotoUid)/\(uniqeId)")
            
            
            let lowResImageData = UIImageJPEGRepresentation(self.images.last!, 0.20)
            _ = pictureStorageRef.putData(lowResImageData!, metadata: nil)
            {metadata, error in
                if (error == nil){
                    
                    pictureStorageRef.downloadURL(completion: { (url, error) in
                        if error != nil {
                            return
                        }
                        if url != nil {
                            
                            let childUpdates = ["/posts/\(FirebaseVariables.uid)/\(editPhotoUid)/fotolar/\(String(fotoSirasi+1))/picture":url!.absoluteString ] as [String : Any]
                            
                            FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).child("eklenmeTarihi").setValue(Date().timeIntervalSince1970)
                            FirebaseVariables.ref.updateChildValues(childUpdates)
                            
                            self.loading.stopAnimating()
                            self.view.isUserInteractionEnabled = true
                            self.imagesUrl.append(url!.absoluteString)
                        }
                    })
                }
            }
            
        }
        
        
        
        imageView.image = images[0]
        
        self.loading.stopAnimating()
    }
    
    
    //fotolarin herhangi birine dokununca  vitrin fotosu yapabilmek icin alert ekliyoruz
    @objc func touchPhotoInScroll(_ sender:UITapGestureRecognizer)
    {
        
        
        var actions: [(String, UIAlertActionStyle)] = []
        actions.append(("Vitrin fotoğrafı yap", UIAlertActionStyle.default))
        actions.append(("Vazgeç", UIAlertActionStyle.cancel))
        
        //self = ViewController
        self.showActionsheet(viewController: self, title: "Seçenekler", message: "General Message in Action Sheet", actions: actions) { (index) in
            
            if (index == 0){
                
                //sectigimiz fotonun vitrin fotosu oldugunu firebase e bu metodla ekkiypruz
                self.adjustMainPhoto(sender)
                
            }
            
        }
        
        
    }
    
    
    
    //sectigimiz fotonun vitrin fotosu oldugunu firebase e bu metodla ekkiypruz
    func adjustMainPhoto(_ sender:UITapGestureRecognizer){
        
        
        var indexPhoto = 0
        if let de = sender.view as? UIImageView {
            
            for image in images {
                
                if de.image == image {
                    
                    let urlString = self.imagesUrl[indexPhoto]!
                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).updateChildValues(["anafoto":urlString])
                    
                    
                    imageView.image = image
                }
                indexPhoto += 1
            }
            
        }
        
    }
    
    
    //ekledigimiz fotolari scrollview a ekliyoruz
    func appendImages(){
        
        for i in 0..<images.count {
            
            let imageView = UIImageView()
            
            let x = (self.view.frame.size.width * CGFloat(i)) / 1.96
            imageView.frame = CGRect(x: x, y: 0, width: self.scrollView.frame.width, height: self.scrollView.frame.height)
            imageView.contentMode = .scaleAspectFit
            imageView.image = images[i]
            
            scrollView.contentSize.width = (scrollView.frame.size.width * CGFloat(i + 1)) / 1.2
            scrollView.addSubview(imageView)
            
            let touchPhotoInScroll = UITapGestureRecognizer(target: self, action: #selector(EditPostVC.touchPhotoInScroll(_:)))
            touchPhotoInScroll.numberOfTapsRequired = 1
            
            
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(touchPhotoInScroll)
            
            
            
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
    
    
    @IBAction func yayinlaBtn(_ sender: Any) {
        
        
        // publish btn foto sectimizden aktif yaptik
        
        
        //sadece foto ve baslik zorunlu alanlar
        if(baslikTxt.text == "" || images.count == 0){
            
            self.showAlert(title: "Hata", message: "Foto ekleme ve ürün başlık kısımlarını lütfen eksiksiz doldurun")
            return
        }
        
        if(sehir == ""){
            
            self.showAlert(title: "Hata", message: "Lutfen isletmenizin adresini haritadan seciniz")
            return
        }
        
        if(fiyatText.text == ""){
            self.showAlert(title: "Hata", message: "Fiyat giriniz")
            return
            
        }
        
        
        verileriGuncelle()
        
    }
    
    func verileriGuncelle() {
        
        FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).child("eklenmeTarihi").setValue(Date().timeIntervalSince1970)
        
            if self.baslikTxt.text != "" {
                FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).child("baslik").setValue(self.baslikTxt.text!)
                }
        
                if self.urunAciklamaTx.text != "" {
                  FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).child("aciklama").setValue(self.urunAciklamaTx.text)
                    
                }
        
                  if self.fiyatText.text != "" {
                  FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).child("fiyat").setValue(self.fiyatText.text)
                 }
        
                                if self.secilenKategori != "" {
                                    
                                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).child("kategori").setValue(self.secilenKategori)
                                }
        
                                if sehir != "" {
                                    
                                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).child("sehir").setValue(sehir)
                                }
        
                                if enlem != "" {
                                    
                                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).child("enlem").setValue(enlem)
                                }
        
                                if boylam != "" {
                                    
                                    FirebaseVariables.ref.child("posts").child(FirebaseVariables.uid).child(editPhotoUid).child("boylam").setValue(boylam)
                                }
        
        
        
        
        
        DispatchQueue.main.async {
            
            
            // publish btn foto sectimizden aktif yaptik
            self.yayinOutlet.isEnabled = true
            self.navigationController?.popViewController(animated: true)
        }
        
        
        
    }

    
    @IBAction func fotoEkle_Action(_ sender: Any) {
        
        
        selectImg()
    }
    
    @IBAction func konumDegistirBtn_Action(_ sender: Any) {
    }
    

    
}
