//
//  Constants.swift
//  LetgoClone
//
//  Created by MacBook  on 26.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage


//firebase'den gelen her deger ve hep kullandigimiz degerleri ekledik
class FirebaseVariables{
    
    static var uid:String{
        
        return Auth.auth().currentUser!.uid
    }
    
    static var ref:DatabaseReference{
        return Database.database().reference()
    }
    
    static var storageRef:StorageReference{
        return Storage.storage().reference()
    }
    
}
