//
//  FilterResultVC.swift
//  LetgoClone
//
//  Created by MacBook  on 15.08.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import Reachability

var photoUidArrayF = [String]()
var photoImageUrlF = [String]()
var userUidF = [String]()

class FilterResultVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var result: UILabel!
    
  
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //collectionview delegate ve datasource bagliyoruz
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //begendigimiz urunleri getiriyoruz
        
        // observe ile konum dgisince postlari dgistiriyoruz hangi sehir ise
        NotificationCenter.default.addObserver(self, selector: #selector(FilterResultVC.filtered), name: NSNotification.Name(rawValue: "filtered"), object: nil)
        

    }
    
    @objc func filtered(){
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

    
    // cell sayisi
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        result.text = "Aranan kriterlerde \(photoUidArrayF.count) tane ürün bulundu."
        return photoUidArrayF.count
    }
    
    // cell yapilandirilmasi yani cell'ler hangi cell'e bagli oldugunu storyboardda verdigimiz id "Cell" ile belli ediyoruz
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // cell'in bir ProfileCell turunde oldugunu belirtiyoruz
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ProfileCell
        
        //burada photoImageUrl dizimizde bi fotoUrl si varsa cell e fotomuzu ekliycez
        if(photoImageUrlF.count>0){
            
            
            //helperFunc a ekledigimiz verifyUrl ile link'in geçerli bi url olup olm kontrol ediyoruz
            let test = self.verifyUrl(urlString: photoImageUrlF[indexPath.row])
            if test {
                
                //ve daha sonra ekledigimiz sdImage kutuphanesi metoduyla url deki fotoyu indirip cell'in imageView'ina veriyoruz
                
//                print(indexPath.row)
//                print(photoImageUrlF[indexPath.row])
                cell.itemImage.sd_setImage(with: URL(string: photoImageUrlF[indexPath.row]), placeholderImage: UIImage(named: "foto"))
                
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
        postPhotoUid.append(photoUidArrayF[indexPath.row])
        postUserUid.append(userUidF[indexPath.row])


        let post = self.storyboard?.instantiateViewController(withIdentifier: "PostVC") as! PostVC
        self.navigationController?.pushViewController(post, animated: true)
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
