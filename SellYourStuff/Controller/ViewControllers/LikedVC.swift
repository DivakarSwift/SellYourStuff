//
//  LikedVC.swift
//  LetgoClone
//
//  Created by MacBook  on 26.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import SDWebImage
import FirebaseDatabase
import Reachability

//begendiklerim sayfasi

class LikedVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    //Cell'lere ekleyecegimiz fotolarin url'lerini bu dizide tutuyoruz
    var photoImageUrl = [String]()
    
    
    //Cell'lere ekleyecegimiz fotolarin url'lerini bu dizide tutuyoruz
    var userUid = [String]()
    
    //urun fotolarinin tutuldugu array
    var photoUidArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        
        //collectionview delegate ve datasource bagliyoruz
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //begendigimiz urunleri getiriyoruz
     fetchLikedItems()
        
        
        
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
    
    
    //begendimiz urunleri getirmek icin bu metodu olusturduk
    func fetchLikedItems(){
        
        FirebaseVariables.ref.child("liked").child(FirebaseVariables.uid).observe(.value, with: { (snapshot) in
            
            self.userUid.removeAll(keepingCapacity: false)
            self.photoImageUrl.removeAll(keepingCapacity: false)
            self.photoUidArray.removeAll(keepingCapacity: false)
            
            var dataSnap:DataSnapshot!
            for questionChild in snapshot.children {
                
                
                dataSnap = questionChild as? DataSnapshot
                let value = dataSnap.value as! NSDictionary
                self.userUid.append(value["owner"] as! String)
                self.photoUidArray.append(dataSnap.key)
                
                
                
                if let picture = value["anafoto"]{
                    self.photoImageUrl.append(picture as! String)
                    
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
                
            }
            
            
        }) { (error) in
            
            self.showAlert(title: "Hata", message: error.localizedDescription)
        }
        
        //ve bu islemlerdne sonra collecitonView'i yeniliyoruz
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
    }
    
    //COLLECTIONVIEW METODLARI
    
   
    
    //COLLECTIONVIEW METODLARI
    
    // cell sayisi
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return photoImageUrl.count
    }
    
    // cell yapilandirilmasi yani cell'ler hangi cell'e bagli oldugunu storyboardda verdigimiz id "Cell" ile belli ediyoruz
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // cell'in bir ProfileCell turunde oldugunu belirtiyoruz
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ProfileCell
        
        //burada photoImageUrl dizimizde bi fotoUrl si varsa cell e fotomuzu ekliycez
        if(photoImageUrl.count>0){
            
            //helperFunc a ekledigimiz verifyUrl ile link'in geçerli bi url olup olm kontrol ediyoruz
            let test = self.verifyUrl(urlString: photoImageUrl[indexPath.row])
            if test {
                
                //ve daha sonra ekledigimiz sdImage kutuphanesi metoduyla url deki fotoyu indirip cell'in imageView'ina veriyoruz
                cell.itemImage.sd_setImage(with: URL(string: self.photoImageUrl[indexPath.row]), placeholderImage: UIImage(named: "foto"))
                
            }else{
                
                self.showAlert(title: "Hata", message: "fotoğraf yüklenirken bir sorun oluştu.")
                
                
            }
        }
        
        
        cell.itemImage.layer.cornerRadius = 8.0
        cell.itemImage.clipsToBounds = true
        
        return cell
        
        
        
    }
    
    //burada her collectionView cell icin deger veriyoruz her satirda 3 cell olsun istiyoruz bunu da hesaplayip ekledik
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let cellWidth = (width - 30) / 3 // ekranın her satirinda 3 tane urun olmasi icin collecitonview cellerimizi 3 e boluyoruz boylece 3er tane ekleidk
        return CGSize(width: cellWidth, height: cellWidth )
    }
    
    
    
    //urunler yani collectionview celleri secilince cagilasan metod 
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        postPhotoUid.append(photoUidArray[indexPath.row])
        postUserUid.append(userUid[indexPath.row])
        
        
        let post = self.storyboard?.instantiateViewController(withIdentifier: "PostVC") as! PostVC
        self.navigationController?.pushViewController(post, animated: true)
    }
    
    
    
    
    
}
