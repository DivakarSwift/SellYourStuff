//
//  EmailUpdateVC.swift
//  LetgoClone
//
//  Created by MacBook  on 8.08.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FacebookLogin
import FirebaseDatabase
import Reachability

class EmailUpdateVC: UIViewController {

    @IBOutlet weak var kaydetBt: UIButton!
    
    @IBOutlet weak var newEmailTxt: UITextField!
    @IBOutlet weak var oldEmailTxt: UITextField! //eski email ile ayni ise islem yapmiyoruz
    var oldEmailFromFirebase:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).observe(.value, with: { (snapshot) in
            
            
            let snapshot = snapshot.value as! NSDictionary
            
            self.oldEmailFromFirebase = snapshot["email"] as! String
            
        })
        
        
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

    @IBAction func kaydetBtn_Action(_ sender: Any) {
        
        kaydetBt.isEnabled = false
        
        if oldEmailTxt.text != oldEmailFromFirebase {
            
            self.showAlert(title: "", message: "Şifreler uyuşmuyor")
            kaydetBt.isEnabled = true
            return
        }
        
        if (oldEmailTxt.text?.isEmpty)! || (newEmailTxt.text?.isEmpty)! {
            
            self.showAlert(title: "", message: "Lütfen tüm alanları doldurun")
            kaydetBt.isEnabled = true
            return
        
        }
        
        if newEmailTxt.text == oldEmailFromFirebase {
            
            self.showAlert(title: "", message: "Zaten bu email ile kayitlisiniz")
            kaydetBt.isEnabled = true
            return
            
        }
        
        
        Auth.auth().currentUser!.updateEmail(to: self.newEmailTxt.text!) { error in
            
            if error == nil {
                FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).updateChildValues(["email" : self.newEmailTxt.text! ], withCompletionBlock: {(errEM, referenceEM)   in
                    
                    if errEM == nil{
                        
                        
                        self.showAlert(title: "Yeni email adresini eklendi", message: "lütfen bu adres ile tekrar giriş yapınız", handler: { (alert: UIAlertAction!) in
                            
                            
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
                            UserDefaults.standard.synchronize()
                            
                            let loginManager = LoginManager()
                            loginManager.logOut()
                            
                            
                            
                            //appdelegate den giris sayfamizi cagiriyoruz
                            let signin = self.storyboard?.instantiateViewController(withIdentifier: "signInVC") as! SignInVC
                            let appDelegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDelegate.window?.rootViewController = signin
                            
                            
                        })
                        
                    }else{
                        self.showAlert(title: "", message: "Bir hata oluştu daha sonra tekrar deneyin.")
                        self.kaydetBt.isEnabled = true
                    }
                })
            }else{
                
                self.kaydetBt.isEnabled = true
                if let hataKodu = AuthErrorCode(rawValue: error!._code) {
                    switch hataKodu {
                    case .invalidEmail:
                        self.showAlert(title: "", message: "Geçersiz bir Email girdiniz.")
                    case .emailAlreadyInUse:
                        self.showAlert(title: "", message: "Bu Email adresi zaten kullanımda.")
                        
                    case .networkError:
                        self.showAlert(title: "", message: "İnternet bağlantınızda bir hata saptandı.")
                    // Yukarıdakilerin dışındaki bir hata için yapılacak default işlem;
                    default:
                        self.showAlert(title: "", message: "Bir hata oluştu daha sonra tekrar deneyin.")
                    }
                }
            }
        }
        
        
        
        
    }
    
    @IBAction func geriBtn_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
