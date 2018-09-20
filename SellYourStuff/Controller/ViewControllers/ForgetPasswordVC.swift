//
//  ForgetPasswordVC.swift
//  Chatto
//
//  Created by MacBook  on 9.08.2018.
//

import UIKit
import Firebase
import FirebaseDatabase
import FacebookLogin
import FacebookCore
import Reachability

class ForgetPasswordVC: UIViewController {

    @IBOutlet weak var sifirlaBtn: UIButton!
    @IBOutlet weak var vazgecBtn: UIButton!
    @IBOutlet weak var emailTxt: UITextField!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func vazgecBtn_Action(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sifirlaBtn_Action(_ sender: Any) {
        
        if emailTxt.text == "" {
            
            self.showAlert(title: "", message: "Email boş olamaz")
            return
            
        }
        
     
            Auth.auth().sendPasswordReset(withEmail: emailTxt.text!, completion: { (error) in
                if error != nil{
                   
                    if let HataKodu = AuthErrorCode(rawValue: error!._code) {
                        switch HataKodu {
                            
                        // Güvenlik açısından hangisinin yanlış hangisinin doğru girildiği kullanıcıya gösterilmez.
                         case .invalidEmail:
                            self.showAlert(title: "", message: "Hatalı email girdiniz.")
                        case .networkError:
                            self.showAlert(title: "", message: "İnternet bağlantınızda bir hata saptandı.")
                        // Yukarıdakilerin dışındaki bir hata için yapılacak default işlem;
                        default:
                            self.showAlert(title: "", message: "Bir hata oluştu lütfen daha sonra tekrar deneyin. ")
                        }
                    }
                    
                }else {
                    self.showAlert(title: "Başarılı", message: "Lütfen email adresinizi kontrol edin")
                }
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
    
   
    
}
