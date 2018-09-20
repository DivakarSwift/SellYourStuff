//
//  SignUpVC.swift
//  LetgoClone
//
//  Created by MacBook  on 26.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import Firebase
import Reachability

class SignUpVC: UIViewController {

    @IBOutlet weak var kaydolBtn: UIButton!
    @IBOutlet weak var vazgecBtn: UIButton!
    @IBOutlet weak var sifreTekrarText: UITextField!
    @IBOutlet weak var sifreText: UITextField!
    @IBOutlet weak var epostaTxt: UITextField!
    @IBOutlet weak var adSoyadText: UITextField!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.kaydolBtn.isEnabled = true
        self.vazgecBtn.isEnabled = true
       
        //internet kontrolu
        let reachability = Reachability()!
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }
    
    
    @IBAction func vazgecBtn_Action(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBAction func kaydolBtn_Action(_ sender: Any) {
        
        
        self.kaydolBtn.isEnabled = false
        self.vazgecBtn.isEnabled = false
        
        
        self.loading.startAnimating()
        
        // dismiss keyboard
        self.view.endEditing(true)
        
        // alanlarin bos kontrolu
        if (adSoyadText.text!.isEmpty || epostaTxt.text!.isEmpty || sifreText.text!.isEmpty || sifreTekrarText.text!.isEmpty ) {
            
            
            self.loading.stopAnimating()
            
            self.showAlert(title: "", message: "Lütfen tüm alanları doldurunuz !")
            
            return
        }
        
        // sifreler uyusuyormu kontrolu
        if (sifreText.text != sifreTekrarText.text) {
            
            
            self.loading.stopAnimating()
            
            self.showAlert(title: "", message: "Şifreler birbiriyle uyuşmuyor")
            
            return
        }
        
        //eger sorun yoksa giris yapiyoruz
        girisYap(eposta: epostaTxt.text!, parola: sifreText.text!)
        
    }
    

    
    
    func girisYap(eposta:String, parola:String){
        
        
        //firebase yeni kullanici yaratiyoruz
        Auth.auth().createUser(withEmail: eposta, password: parola, completion: { (user, error) in
            
            if(error != nil) // HATA BOŞ DEĞİLSE
            {
                
                self.kaydolBtn.isEnabled = true
                self.vazgecBtn.isEnabled = true
                
                self.loading.stopAnimating()
                
                if let hataKodu = AuthErrorCode(rawValue: error!._code) {
                    
                    self.loading.stopAnimating()
                    
                    switch hataKodu {
                    case .invalidEmail:
                        self.showAlert(title: "", message: "Geçersiz bir Email girdiniz.")
                    case .emailAlreadyInUse:
                        self.showAlert(title: "", message: "Bu Email adresi zaten kullanımda.")
                    case .weakPassword:
                        self.showAlert(title: "", message: "Belirlediğiniz şifre çok zayıf.")
                     
                    case .networkError:
                        self.showAlert(title: "", message: "İnternet bağlantınızda bir hata saptandı.")
                    // Yukarıdakilerin dışındaki bir hata için yapılacak default işlem;
                    default:
                        self.showAlert(title: "", message: "Bir hata oluştu daha sonra tekrar deneyin.")
                    }
                }
            } else{
                
                //kullanicinin adini soyadini firebase db kaydediyoruz
                FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("fullName").setValue(self.adSoyadText.text)
                FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("email").setValue(self.epostaTxt.text)
                
                
                //burada mapvc de kullanmak icin bir global degisken var bunu true yaptik
                //bu sayede mapvc de iki farkli islemi bu degiskene gore yapar
                //true ise anasayfayı acar false ise urun icin konum sectigimizi anlar ve islemden sonra sayfayi kapatir
                isComingForUsers = true
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let mapVC = storyboard.instantiateViewController(withIdentifier: "MapVC") as! MapVC
                
                email = self.epostaTxt.text!
                password = self.sifreText.text!
                fullname = self.adSoyadText.text!
                self.loading.stopAnimating()
                
                self.present(mapVC, animated: true, completion: nil)
                
                
            }
        })
    }
    
    
}
