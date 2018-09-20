//
//  SignInVC.swift
//  LetgoClone
//
//  Created by MacBook  on 25.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import Firebase
import FacebookLogin
import FacebookCore
import Reachability

class SignInVC: UIViewController {

   
    @IBOutlet weak var twButton: UIButton!
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var sifremiUnuttumBtn: UIButton!
    @IBOutlet weak var girisYapBtn: UIButton!
    @IBOutlet weak var emailTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var kayitOl: UIButton!
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var logoImage: UIImageView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
      
       
        girisYapBtn.imageView?.contentMode = .scaleAspectFit
        kayitOl.imageView?.contentMode = .scaleAspectFit
        fbButton.imageView?.contentMode = .scaleAspectFit
        twButton.imageView?.contentMode = .scaleAspectFit
        
        
        //fb giris yap butonumuza dokununca fbLoginButton metodu tetiklenir
        fbButton.addTarget(self, action: #selector(SignInVC.fbLoginButton), for: .touchUpInside)
        
        self.view.isHidden = true
        
    }
    
    //ekranimizi transitionCrossDissolve animasyonu ile aciyoruz
    override func viewDidAppear(_ animated: Bool) {
        UIView.transition(with: view, duration: 0.8, options: .transitionCrossDissolve, animations: {
            
            self.view.isHidden = false
            
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
    
    
    
    //giris butonu
    @IBAction func girisBtn_action(_ sender: Any) {
        
        
        self.loading.startAnimating()
        
        // keyboard gizleme
        self.view.endEditing(true)
        
        if (emailTxt.text!.isEmpty || passwordTxt.text!.isEmpty) {
            
            
            self.loading.stopAnimating()
            self.showAlert(title: "", message: "Lütfen tüm alanları doldurunuz !")
            
            return
        }
        
        //eger alanlar bos degilse signInWithEmail() metodu ile giriş yapiyoruz
        signInWithEmail(emaill: emailTxt.text!, pass: passwordTxt.text!)
        
       
        
    }
    
    
    //fb ile giris yap metodu
    @objc func fbLoginButton() {
        self.loading.startAnimating()
        
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.email], viewController: self) { (result) in
            switch result {
            case .failed(let error):
                print(error)
                self.loading.stopAnimating()
            case .cancelled:
                print("User cancelled login.")
                self.loading.stopAnimating()
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                MyProfileRequest().start {[unowned self]  (req, result) in
                    switch result {
                    case .success(let values): 
                        
                        //credential degiskenini fbProvider dan alıyoruz
                        let cr = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                        
                        //firebase e giris yapiyoruz - fbProvider ile
                        Auth.auth().signInAndRetrieveData(with: cr) { (authResult, error) in
                            if let error = error {
                                self.showAlert(title: "Hata", message: error.localizedDescription)
                             
                                
                                return
                            }
                            
                            
                            
                            //fb ile aldigimiz kullanicinin adini soyadini firebase db kaydediyoruz
                            FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("fullName").setValue(values.name!)
                            FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("email").setValue(values.email!)
                            FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("girisType").setValue("fb")
                            
                            
                                FirebaseVariables.ref.child("users").queryOrdered(byChild: "email").queryEqual(toValue: values.email!).observe(.childAdded) { (snapshot) in
                                
                                let value = snapshot.value as? NSDictionary
                                
                                
                                    self.loading.stopAnimating()
                                    
                                //eger enlem yoksa kullanicinin konumu belli degildir bundan dolayi mapVC ye yolluyoruz
                                if(value?["enlem"] == nil){
                                    
                                    isComingForUsers = true
                                    
                                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                    let mapVC = storyboard.instantiateViewController(withIdentifier: "MapVC") as! MapVC
                                    
                                    email = self.emailTxt.text!
                                    password = self.passwordTxt.text!
                                    self.loading.stopAnimating()
                                    
                                    self.present(mapVC, animated: true, completion: nil)
                                    
                                    //konumunu daha once belirlemisse userDef kaydediyoruz
                                    //tekrar cikinca giris ekrnai gelmesin diye ve ana ekrana yolluyoruz
                                }else{
                                    // eger boyle bi kullanici varsa userdefault a kaydediyoruz
                                    UserDefaults.standard.set(values.email!, forKey: "email")
                                    UserDefaults.standard.synchronize()
                                    
                                    //ve appdelegate deki login() meotdu ile userdefault'da bir deger oldugundan (yukaridaki kod ile) anasayfaya gidiyoruz
                                    let appDelegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                                    
                                    self.loading.stopAnimating()
                                    appDelegate.loginAsUser()
                                    
                                }
                            }
                            
                            
                            
                        }
                        
                        
                    case .failed(let error):
                        print("Custom Graph Request Failed: \(error)")
                        self.loading.stopAnimating()
                    }
                }
                
                
            }
        }
        
    }
    
    
    //email ile giris yapma metdu
    func signInWithEmail(emaill:String, pass:String){
        
        //email sifre ile giris yapiyoruz
        Auth.auth().signIn(withEmail: emaill, password: pass, completion: { (user, error) in
            if(error != nil)
            {
                
                
                self.loading.stopAnimating()
                //hatalarin varsa kontrolu
                if let HataKodu = AuthErrorCode(rawValue: error!._code) {
                    self.loading.stopAnimating()
                    switch HataKodu {
                        
                    // Güvenlik açısından hangisinin yanlış hangisinin doğru girildiği kullanıcıya gösterilmez.
                    case .wrongPassword:
                        self.showAlert(title: "", message: "Hatalı email veya şifre girdiniz.")
                    case .invalidEmail:
                        self.showAlert(title: "", message: "Hatalı email veya şifre girdiniz.")
                    case .networkError:
                        self.showAlert(title: "", message: "İnternet bağlantınızda bir hata saptandı.")
                    // Yukarıdakilerin dışındaki bir hata için yapılacak default işlem;
                    default:
                        self.showAlert(title: "", message: "Bir hata oluştu lütfen daha sonra tekrar deneyin. ")
                    }
                }
                
            }
            else
            {
                //kullaniciya ait bilgilere bakiyoruz daha once konumunu belirtmismi diye
                FirebaseVariables.ref.child("users").queryOrdered(byChild: "email").queryEqual(toValue: emaill).observe(.childAdded) { (snapshot) in
                    
                    let value = snapshot.value as? NSDictionary
                    
                    
                    
                    if(value?["enlem"] == nil){
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let mapVC = storyboard.instantiateViewController(withIdentifier: "MapVC") as! MapVC
                        isComingForUsers = true
                        
                        
                        email = emaill
                        password = pass
                        fullname = value?["fullName"] as! String
                        
                        
                        self.loading.stopAnimating()
                        
                        self.present(mapVC, animated: true, completion: nil)
                        
                    }else{
                        
                        // eger boyle bi kullanici varsa userdefault a kaydediyoruz
                        UserDefaults.standard.set(emaill, forKey: "email")
                        UserDefaults.standard.set(self.passwordTxt.text!, forKey: "password")
                        UserDefaults.standard.synchronize()
                        
                        //ve appdelegate deki login() meotdu ile userdefault'da bir deger oldugundan (yukaridaki kod ile) anasayfaya gidiyoruz
                        let appDelegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
                        
                        self.loading.stopAnimating()
                        appDelegate.loginAsUser()
                    }
                }
            }
        })
        
    }
    
 
    @IBAction func loginWithTwitter(_ sender: Any) {
        

    }
    
}

