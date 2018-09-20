//
//  EditOnlyLocationVC.swift
//  LetgoClone
//
//  Created by MacBook  on 17.08.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import Reachability

class EditOnlyLocationVC: UIViewController {

    @IBOutlet weak var konumDegistirBtn: UIButton!
    @IBOutlet weak var KonumTxt: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem?.tintColor = UIColor(red: 37.0 / 255.0, green: 79.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)
        
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 37.0 / 255.0, green: 79.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        KonumTxt.text = sehir
        KonumTxt.sizeToFit()
    
        //internet kontrolu
        let reachability = Reachability()!
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }
    

    @IBAction func konumDegistir_Action(_ sender: Any) {
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mapVC = storyboard.instantiateViewController(withIdentifier: "MapVC") as! MapVC
        
        isComingForUsers = true
        
        self.present(mapVC, animated: true, completion: nil)
        
    }
    
    @IBAction func backBtn(_ sender: Any) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
    
}
