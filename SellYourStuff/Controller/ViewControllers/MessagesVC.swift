//
//  MessagesVC.swift
//  LetgoClone
//
//  Created by MacBook  on 7.08.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwiftyJSON
import FirebaseDatabase
import FirebaseDatabaseUI
import Chatto
import Reachability

class MessagesVC: UIViewController, FUICollectionDelegate, UITableViewDelegate, UITableViewDataSource {

    
    // FirebaseDatabaseUI ile onun tipinde bir FUISortedArray Olusturduk burada listemize ekledigimiz kisiler var
    //burada mesajlarimiz tutulucak ve burada onemli nokta (lhs, rhs) ile en son hangisiyle konustuysa o listede yukarda durur
    let contacts = FUISortedArray(query: Database.database().reference().child("users").child(FirebaseVariables.uid).child("Contacts"), delegate: nil) { (lhs, rhs) -> ComparisonResult in
        let lhs = Date(timeIntervalSinceReferenceDate: JSON(lhs.value as Any)["lastMessage"]["date"].doubleValue)
        let rhs = Date(timeIntervalSinceReferenceDate:JSON(rhs.value as Any)["lastMessage"]["date"].doubleValue)
        return rhs.compare(lhs)
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var emailAdress = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //observeQuery() metodu sayesinde contacts dizimizin tasidigi veritabani dizininde herhangi bi olay (ekleme, cikarma vb) oldugunda asagiya ekledimiz FUI tetiklecek
        self.contacts.observeQuery()
        
        self.contacts.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        
        
        //burada eger internet baglantisi yoksa uid ye ait mesajlari cache bellekten getir dedik
        //uygulamımızın offline ikende kullanilmasini sagladik
        FirebaseVariables.ref.child("User-messages").child(FirebaseVariables.uid).keepSynced(true)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        emailAdress.removeAll(keepingCapacity: false)
        
    FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).child("Contacts").observeSingleEvent(of: .value, with: {  [weak self] (snapshot) in
        
        var dataSnap:DataSnapshot!
        var childFotoNesneleriDict:NSDictionary!
        
        
        for questionChild in snapshot.children {
            
            dataSnap = questionChild as? DataSnapshot
            childFotoNesneleriDict = dataSnap?.value as! NSDictionary
            self?.emailAdress.append(childFotoNesneleriDict["email"]! as! String)
        }
            
        })
        
        
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

//burada FUI metodlarini ve table view metodlarini yazdık
extension MessagesVC{
    
    //burada altalta 4 tane FUI metodu var bunlar yukaridaki contantc dizimizde (ekleme silme)
    //vb. olaylar olunca ilgili metod calisir
    func array(_ array: FUICollection, didAdd object: Any, at index: UInt) {
        self.tableView.insertRows(at: [IndexPath(row: Int(index), section: 0)], with: .automatic)
    }
    
    func array(_ array: FUICollection, didMove object: Any, from fromIndex: UInt, to toIndex: UInt) {
        self.tableView.insertRows(at: [IndexPath(row: Int(toIndex), section: 0)], with: .automatic)
        self.tableView.deleteRows(at: [IndexPath(row: Int(fromIndex), section: 0)], with: .automatic)
        
        
    }
    func array(_ array: FUICollection, didRemove object: Any, at index: UInt) {
        self.tableView.deleteRows(at: [IndexPath(row: Int(index), section: 0)], with: .automatic)
        
        
    }
    func array(_ array: FUICollection, didChange object: Any, at index: UInt) {
        self.tableView.reloadRows (at: [IndexPath(row: Int(index), section: 0)], with: .none)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(self.contacts.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messagesCell", for: indexPath) as! MessageCell
        let info = JSON((contacts[(UInt(indexPath.row))] as? DataSnapshot)?.value as Any).dictionaryValue
        cell.adSoyadTxt.text = info["fullName"]?.stringValue
        
        cell.messageTxt.text = info["lastMessage"]?["text"].string
        cell.tarihTxt.text = dateFormatter(timestamp: info["lastMessage"]?["date"].double)
        
        //verifyUrl metodumuzla foto linkimizin geçerli bir link olup olmadigini kulaniyoruz
        let test = self.verifyUrl(urlString: info["profilfoto"]?.stringValue)
        if test && info["profilfoto"]?.stringValue != nil{
            
            //ve daha sonra ekledigimiz sdImage kutuphanesi metoduyla url deki fotoyu indirip cell'in imageView'ina veriyoruz
            cell.imagee.sd_setImage(with: URL(string: info["profilfoto"]!.stringValue as! String), placeholderImage: UIImage(named: "foto"))
            
        }else{
            
            
            
        }
        
        
        cell.imagee.layer.cornerRadius = 8.0
        cell.imagee.clipsToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let uid = (contacts[UInt(indexPath.row)] as? DataSnapshot)?.key
        let reference = FirebaseVariables.ref.child("User-messages").child(FirebaseVariables.uid).child(uid!).queryLimited(toLast: 51) //normalde ChatDataSourceProtocol da 50 mesaj olarak belirtmistik ancak bir burada 1 fazlasini belirtiyoruz bu 51. mesaj gozukmez ancak bunun nedeni eger bir daha load yani eski mesaj yuklersek
        //bu mesaj ve ustundeki yuklemeek icin adres belli eder
        
        self.tableView.isUserInteractionEnabled = false //bunu en baska false yaptik cunku kullanicinin mesajlar yuklenirken baska islem yapamasin !
        
        reference.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            //burada snaphot da key-value olarak "User-messages" icinden mesajlarizi aldik ve tarihe gore sıraladık
            let messages = Array(JSON(snapshot.value as Any).dictionaryValue.values).sorted(by: { (lhs, rhs) -> Bool in
                
                return lhs["date"].doubleValue < rhs["date"].doubleValue
            })
            
            let converted = self?.convertToChatItemProtocol(messages: messages)
            //burada json olarak aldigimiz mesaji helper dosyasinda
            //olusturdumuz bi metodla ChatItemProtocol a ceviriyoruz
            
            let chatlog = ChatLogController()
            chatlog.userUID = uid!
            chatlog.dataSource = DataSource(initialMessages: converted!, uid: uid!)
            
            chatlog.messagesArray = FUIArray(query: FirebaseVariables.ref.child("User-messages").child(FirebaseVariables.uid).child(uid!).queryStarting(atValue: nil, childKey: converted?.last?.uid), delegate: nil)
            
            self?.navigationController?.show(chatlog, sender: nil)
            self?.tableView.deselectRow(at: indexPath, animated: true)
            self?.tableView.isUserInteractionEnabled = true // ve mesajlar yuklenince tekrar dokunmayi aktif yaptik
            
            //eger yuklenen mesajlar icinde foto varsa bunu helperdaki parseURLs() metodumuzla fotoya cevirip yukleriz
            
            messages.filter({ (message) -> Bool in
                return message["type"].stringValue == PhotoModel.chatItemType
            }).forEach({ (message) in
                
                
                self?.parseURLs(UID_URL: (key: message["uid"].stringValue, value: message["image"].stringValue))
            })
            
        })
        
    }
    
    
  
    
}

