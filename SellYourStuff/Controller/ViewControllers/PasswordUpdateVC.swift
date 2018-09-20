//
//  PasswordUpdateVC.swift
//  LetgoClone
//
//  Created by MacBook  on 8.08.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import Firebase
import FacebookLogin
import Reachability

class PasswordUpdateVC: UIViewController {

    
    @IBOutlet weak var newPasswordAgain: UITextField!
    @IBOutlet weak var newPasswordTxt: UITextField!
    @IBOutlet weak var kaydetBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
      
        
    }

    @IBAction func kaydetBtn_Action(_ sender: Any) {
        
        kaydetBtn.isEnabled = false
        
        if newPasswordTxt.text != newPasswordAgain.text {
            
            self.showAlert(title: "", message: "Şifreler uyuşmuyor")
            kaydetBtn.isEnabled = true
            return
        }
        
        if (newPasswordTxt.text?.isEmpty)! || (newPasswordAgain.text?.isEmpty)! {
            
            self.showAlert(title: "", message: "Lütfen tüm alanları doldurun")
            kaydetBtn.isEnabled = true
            return
            
        }
        
        
        let email = UserDefaults.standard.string(forKey: "email")!
        let password = UserDefaults.standard.string(forKey: "password")!
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        print(email)
        print(password)
        
        Auth.auth().currentUser?.reauthenticateAndRetrieveData(with: credential, completion: { (authResult, error) in
          
            if error == nil {
                Auth.auth().currentUser?.updatePassword(to: self.newPasswordTxt.text!) { (errror) in
                
                   
                if(errror == nil)
                {
                    self.showAlert(title: "Şifreniz değiştirildi", message: "lütfen bu şifre ile tekrar giriş yapınız", handler: { (alert: UIAlertAction!) in
                      
                        
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
                    
                    self.kaydetBtn.isEnabled = true
                    
                    if let hataKodu = AuthErrorCode(rawValue: error!._code) {
                        switch hataKodu {
                        case .weakPassword:
                            self.showAlert(title: "", message: "Daha güçlü bir şifre girin lütfen")
                            
                        default:
                            self.showAlert(title: "", message: "Bir hata oluştu daha sonra tekrar deneyin.")
                        }
                    }
                }
                
                
                }
                
            }
        })
        
    }
    
    
    @IBAction func geriBtn_Action(_ sender: Any) {
        
        self.navigationController?.popViewController(animated: true)
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
