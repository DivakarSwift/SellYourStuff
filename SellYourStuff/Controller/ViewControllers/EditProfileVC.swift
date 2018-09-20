//
//  EditProfileVC.swift
//  LetgoClone
//
//  Created by MacBook  on 8.08.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import Firebase
import Reachability

class EditProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
 
    

    @IBOutlet weak var konumDegistirBtn: UIButton!
    @IBOutlet weak var ppDegistirBtn: UIButton!
    @IBOutlet weak var adSoyadTxt: UITextField!
    @IBOutlet weak var konumLbl: UILabel!
    
    @IBOutlet weak var imageV: UIImageView!
    
    var firstFullname = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor(red: 37.0 / 255.0, green: 79.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)
        
     self.navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 37.0 / 255.0, green: 79.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)
        
        imageV.layer.cornerRadius = 5
        imageV.layer.masksToBounds = true
        

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        //bilgileri getiyoruz
        FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).observe(.value, with: { (snapshot) in
            
            
            let snapshot = snapshot.value as! NSDictionary
            
            self.adSoyadTxt.text = snapshot["fullName"] as? String
            self.firstFullname = snapshot["fullName"] as! String
            
            //self.konumTxt.text = snapshot["konum"] as? String
            
            
            if let konum = snapshot["konum"]{
                
                self.konumLbl.text = konum as? String
                
            }
            
            
            if let profilPicture = snapshot["profilfoto"]{
                
                self.imageV.sd_setImage(with: URL(string: profilPicture as! String), placeholderImage: UIImage(named: "foto"))
                
            }
            
        })
        
        self.adSoyadTxt.sizeToFit()
        self.konumLbl.sizeToFit()
    
        //internet kontrolu
        let reachability = Reachability()!
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }
        

    @IBAction func geriBtn_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func kaydetBtn_action(_ sender: Any) {
        
        
        
       
        if adSoyadTxt.text == "" {
            
            self.showAlert(title: "", message: "Adınızı boş bırakamazsınız !")
            return
        }
        
        

        
        FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("fullName").setValue(adSoyadTxt.text!)
        
            fullname = adSoyadTxt.text!
        
            //self.showAlert(title: "", message: "İsminiz başarıyla güncellendi !")
        
        
        
        // observe ile konum dgisince HomceVC deki postlari dgistiriyoruz hangi sehir ise

        self.showAlert(title: "Başarılı", message: "Başarı ile güncellendi")
        
        
    }
    
    
 
    
    @IBAction func pp_degistir(_ sender: Any) {
        
        
        selectImg()
    }
    
    
    
    func selectImg() {
        
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    // secilen fotoyu imageview yukler ve foto secim ekranini kapatir
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        imageV.image = info[UIImagePickerControllerEditedImage] as? UIImage
        
        let pictureStorageRef =    FirebaseVariables.storageRef.child("user_profiles/\(FirebaseVariables.uid)/profilePhoto")
        
        
        let lowResImageData = UIImageJPEGRepresentation(imageV.image!, 0.20)
        _ = pictureStorageRef.putData(lowResImageData!, metadata: nil)
        {metadata, error in
            if (error == nil){
                
                
                pictureStorageRef.downloadURL(completion: { (url, error) in
                    if error != nil {
                        return
                    }
                    if url != nil {
                        
                        FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("profilfoto").setValue(url!.absoluteString)
        
                        
                        self.showAlert(title: "", message: "Profil fotosu başarıyla değiştirildi !")
                        
                    }
                    
                })
                
        
            }
        }
        
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func konumDegistir_Action(_ sender: Any) {
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mapVC = storyboard.instantiateViewController(withIdentifier: "MapVC") as! MapVC
        
        isComingForUsers = true
        
        self.present(mapVC, animated: true, completion: nil)
        
    }
    
    
    
}
