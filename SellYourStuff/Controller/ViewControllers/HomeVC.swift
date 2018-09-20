//
//  HomeVC.swift
//  LetgoClone
//
//  Created by MacBook  on 30.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import FirebaseAuth
import FirebaseStorage
import FirebaseAnalytics
import FirebaseDatabase
import Reachability



class HomeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating,UISearchBarDelegate, UISearchControllerDelegate {
    
    
    @IBOutlet weak var filterViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var filterViewLeading: NSLayoutConstraint!
    @IBOutlet weak var konumConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var collectionViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var tableViewLeading: NSLayoutConstraint!
    @IBOutlet weak var collectionViewLeading: NSLayoutConstraint!
    
    @IBOutlet weak var filterResultView: UIView!
    @IBOutlet weak var collectionView: UICollectionView! //satilik urunler
    @IBOutlet weak var map_icon: UIImageView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var konumView: UIView!
    @IBOutlet weak var konumLbl: UILabel!
    
    
    //filter buttons outlets
    @IBOutlet weak var last7DaysBtn: UIButton!
    @IBOutlet weak var last14DaysButton: UIButton!
    @IBOutlet weak var last30DaysButton: UIButton!
    @IBOutlet weak var telefonBtn: UIButton!
    @IBOutlet weak var evBtn: UIButton!
    @IBOutlet weak var evEsyasiBtn: UIButton!
    @IBOutlet weak var yedekParcaBtn: UIButton!
    @IBOutlet weak var carBtn: UIButton!
    @IBOutlet weak var artanBtn: UIButton!
    @IBOutlet weak var azalanBtn: UIButton!
    
    
    
    
    //filtreleme outlets
    @IBOutlet weak var clearAllFilters_Action: UIButton!
    @IBOutlet weak var showFiltersTxt: UILabel!
    
    
    // sectigimiz konumdaki kullanicilari usersArray
    var itemsArray = [NSDictionary?]()
    var filterArray = [NSDictionary?]()
    
    var filterButton:UIButton!
    var vieww:UIView?
    
    //ekranı asagi cekince urunleri yenliyoruz
    var refresher : UIRefreshControl!
    
    //searchbar a herhangi bir kelime girince eger o kullaninin baslik degerine esitse de
    //o kullanicilari filteredUsers dizisinde tutucaz
    var filteredUsers = [NSDictionary?]()
    var photoUidArrayFiltered = [String]()
    var userUidArrayFiltered = [String]()
    
    var dateFilter = ""
    var categoryFilter = ""
    var priceFilter = ""
    
    //searchbar olusturduk
    let searchController:UISearchController = UISearchController(searchResultsController:nil)
    
    //sidebar menumuzu basta gizliyoruz filter butonuna basinca cikicak
    var sideMenu = false
    
    //Cell'lere ekleyecegimiz fotolarin url'lerini bu dizide tutuyoruz
    var photoImageUrl = [String]()
    
    var photoUidArray = [String]()
    var userUid = [String]()
    
    var loggedInUser:User?
    var myCity:String?
    
    
    // her pagination da 20 foto yuklenecek
    var page : Int = 18
    
    //burada eger urunler yuklenirken pagination aninda yuklenen urun sayisi firebase deki veri sayisina esit ise daha fazla yuklemiyoruz bunu bu degiskenle kontrol edicez boylece
    //gereksiz sorgu yapmiyoruz
    
    var snapshotChildrenCount:Int = 0
    
    var isScrollable:Bool = true //scroll down metodumuzu kontrol icin kullaniyoruz sadece collectionview icin scrolldown olayi olucak
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isScrollable = true
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        
       
       
        self.loggedInUser = Auth.auth().currentUser
        
        self.collectionView?.alwaysBounceVertical = true
        
        self.navigationItem.title = "Home"
        
        
        self.konumView.layer.cornerRadius = 8
        self.konumView.clipsToBounds = true
        
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        
        //searchbar ile ilgili ayarlar
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = true
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.returnKeyType = .done
       
        searchController.searchBar.frame = CGRect(x: -6, y: -4, width: self.view.frame.size.width-50, height: (self.navigationController?.navigationBar.frame.size.height)!)
        searchController.searchBar.becomeFirstResponder()
        
        //navgiaitoncontrollerın title kismi searchbarimizi koyduk
        //self.navigationItem.titleView = searchController.searchBar

       

        
        self.searchController.searchBar.sizeToFit()
        
        //Stack View
        vieww  = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
       
        filterButton = UIButton(type: .custom)
        filterButton.frame = CGRect(x: (vieww?.frame.size.width)! - 60, y: 4, width: 50, height: 50)
        filterButton.imageView?.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        filterButton.imageView?.contentMode = .scaleAspectFit
        
        // filterButton.imageEdgeInsets = UIEdgeInsetsMake(100, 100, 100, 100)
        filterButton.setImage(#imageLiteral(resourceName: "filter"), for: .normal)
        filterButton.sizeToFit()
        
        let logoTap = UITapGestureRecognizer(target: self, action: #selector(HomeVC.filter))
        logoTap.numberOfTapsRequired = 1
        filterButton.isUserInteractionEnabled = true
        filterButton.addGestureRecognizer(logoTap)
        
        
        //stackView.addArrangedSubview(textLabel)
        vieww?.addSubview(searchController.searchBar)
        
        vieww?.addSubview(filterButton)
        
        self.navigationItem.titleView = vieww
        
        
       
        
        
        let konumTap = UITapGestureRecognizer(target: self, action: #selector(HomeVC.changeLocation))
        konumTap.numberOfTapsRequired = 1
        konumView.isUserInteractionEnabled = true
        konumView.addGestureRecognizer(konumTap)
        
        
        //anasayfaya urunleri getiryoruz daha sonra bu metod konum degisince, secilen bolgeye bir urun eklenince kendisi calisacak urunler yenilecek
        fetchItems()
       
        
        self.collectionView?.reloadData()
        self.searchController.searchBar.delegate = self

        clearAllFilterInLabel()
        
        
        // asagi cekince sayfayı yenileme olayı
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(HomeVC.refresh), for: UIControlEvents.valueChanged)
        collectionView?.addSubview(refresher)
        
        
    }

    
    @objc func refresh() {
        
        //sayfa yenilyince page 0 lıyoruz cunku sayfada pagination olayini da sifirlamimiz gerek
        page = 0
        snapshotChildrenCount = 0
        loadMore()
    }
    
    
    
    @objc func changeLocation(){
        
        
         let storyboard = UIStoryboard(name: "Main", bundle: nil)
         let editVC = storyboard.instantiateViewController(withIdentifier: "editOnlyLocation") as! EditOnlyLocationVC
         
         self.navigationController?.pushViewController(editVC, animated: true)
        
        
    }
  
    
    @objc func filter(){
        
        
        if !sideMenu {
            
            self.searchController.searchBar.isUserInteractionEnabled = false
            tableViewLeading.constant = -200
            tableViewTrailing.constant = -200
            collectionViewLeading.constant = -200
            collectionViewTrailing.constant = 200
            filterViewLeading.constant = -200
            filterViewTrailing.constant = -200
            
            //konumView.isHidden = true
           // self.filterResultView.isHidden = false
            
            
            sideMenu = true
        } else {
            
            self.searchController.searchBar.isUserInteractionEnabled = true
            tableViewLeading.constant = 0
            collectionViewLeading.constant = 0
            tableViewTrailing.constant = 0
            collectionViewTrailing.constant = 0
            filterViewLeading.constant = 0
            filterViewTrailing.constant = 0
            
            //            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            //                self.konumView.isHidden = false
            //            })
            //self.collectionView.isHidden = false
            
            //2
            sideMenu = false
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) 
        
    }
    
    
    // searchbar a dokununca calisan metod
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        isScrollable = false
        
        
        self.clearOnlyArrayAndViews()
        self.clearAllFilterInLabel()
        
        filterButton.isHidden = true
        
        UIView.transition(with: view, duration: 0.1, options: .transitionCrossDissolve, animations: {
            
            
            // hide collectionView when started search
            self.collectionView.isHidden = true
           // self.konumView.isHidden = true
            self.filterResultView.isHidden = true
            
            
        })
        // searchbar cancel butonu ekleme
        searchBar.showsCancelButton = true
        
    }
    
    
    //searchbar cancel buton tiklama
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        
        isScrollable = true
        
        filterButton.isHidden = false
        
        searchController.searchBar.frame = CGRect(x: -6, y: -4, width: self.view.frame.size.width-50, height: (self.navigationController?.navigationBar.frame.size.height)!)
        self.searchController.searchBar.sizeToFit()
        searchBar.sizeToFit()
        
        UIView.transition(with: view, duration: 0.1, options: .transitionCrossDissolve, animations: {
            
            
            
            self.collectionView.isHidden = false
           // self.konumView.isHidden = false
            self.filterResultView.isHidden = false
            
            
        })
        // klavyeyi gizliyoruz
        searchBar.resignFirstResponder()
        
        // cancel buton gilziyoruz
        searchBar.showsCancelButton = false
        
        
        searchBar.text = ""
        
    }
    
    
 
   
   //burada urunleri getiyoruz hangi sehirdeysek o urunleri getiriyoruz
    @objc func fetchItems(){
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        loading.startAnimating()
        filterButton.isUserInteractionEnabled = false
        
        self.filterResultView.isUserInteractionEnabled = false
        
        FirebaseVariables.ref.child("users").child(FirebaseVariables.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let userValue = snapshot.value as! NSDictionary
            
            
            fullname = userValue["fullName"] as! String
            
            if let konum = userValue["konum"] as? String {
                
                self.myCity = konum
                sehir = konum 
                self.map_icon.isHidden = false
                self.konumLbl.text = self.myCity
                self.konumLbl.sizeToFit()
                
            }
            
            if let enlemim = userValue["enlem"] as? String {
                enlem = enlemim
            }
            
            if let boylamim = userValue["boylam"] as? String {
                boylam = boylamim
            }
            
            FirebaseVariables.ref.child("posts").observe(.childAdded, with: { (snapshot) in
              
                
                var dataSnap:DataSnapshot!
                var childFotoNesneleriDict:NSDictionary!
                
                self.photoUidArray.removeAll(keepingCapacity: false)
                self.userUid.removeAll(keepingCapacity: false)
                self.photoImageUrl.removeAll(keepingCapacity: false)
                
                let key = snapshot.key
                //kendi postumuz ise o postu es geciyoruz
                if(key != self.loggedInUser?.uid)
                {
                    
                    //burada filter mentigi ile kendi sehrimizdeki urunleri collectionview a ekliyoruz
                    FirebaseVariables.ref.child("posts").child(key).queryOrdered(byChild: "sehir").queryEqual(toValue: self.myCity).queryLimited(toFirst: 18).observeSingleEvent(of: .value) { (snapshot) in
                        
                        
                        
                        
                        for questionChild in snapshot.children {
                            dataSnap = questionChild as? DataSnapshot
                            childFotoNesneleriDict = dataSnap?.value as! NSDictionary
                            
                            
                        let photoId = dataSnap.key
                        self.photoUidArray.append(photoId)
                        
                        
                        self.userUid.append(key)
                        
                        let value = dataSnap.value as? NSDictionary
                        self.photoImageUrl.append(value!["anafoto"]! as! String)
                        
                        self.collectionView.insertItems(at:[IndexPath(row:self.photoImageUrl.count-1,section:0)])
                        
                        
                        self.itemsArray.append(value)
                        //insert the rows
                        //self.tableView.insertRows(at: [IndexPath(row:self.itemsArray.count-1,section:0)], with: UITableViewRowAnimation.automatic)
                        
                        
                        self.loading.stopAnimating()
                        
                        
                    }
                    }
                }
            })
            
            UIApplication.shared.endIgnoringInteractionEvents()
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            self.tableView.reloadData()
            self.loading.stopAnimating()
            
            self.filterButton.isUserInteractionEnabled = true
            self.filterResultView.isUserInteractionEnabled = true
            
        }) { (error) in
            
            self.showAlert(title: "", message: error.localizedDescription)
        }
        
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
    }
    
    //eger scrollview asagi cekilirse loadmore metodumuz tetiklenecek
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        let currentOffset = scrollView.contentOffset.y
        let maxOffset = scrollView.contentSize.height - scrollView.frame.size.height
        if maxOffset - currentOffset <= 40{
            
            if isScrollable {
            loadMore()
            }
        }
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
    
   
    
    func loadMore(){
        
        if photoImageUrl.count == snapshotChildrenCount {
            return
        }
        
        self.photoUidArray.removeAll(keepingCapacity: false)
        self.userUid.removeAll(keepingCapacity: false)
        self.photoImageUrl.removeAll(keepingCapacity: false)
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        page += 18
        
        loading.startAnimating()
        filterButton.isUserInteractionEnabled = false
        
        self.filterResultView.isUserInteractionEnabled = false
        
        
            
            FirebaseVariables.ref.child("posts").observe(.childAdded, with: { (snapshot) in
                
                
                var dataSnap:DataSnapshot!
                var childFotoNesneleriDict:NSDictionary!
                
                self.photoUidArray.removeAll(keepingCapacity: false)
                self.userUid.removeAll(keepingCapacity: false)
                self.photoImageUrl.removeAll(keepingCapacity: false)
                
                let key = snapshot.key
                //kendi postumuz ise o postu es geciyoruz
                if(key != self.loggedInUser?.uid)
                {
                    
                    //burada filter mentigi ile kendi sehrimizdeki urunleri collectionview a ekliyoruz
                    FirebaseVariables.ref.child("posts").child(key).queryOrdered(byChild: "sehir").queryEqual(toValue: self.myCity).queryLimited(toFirst: UInt(self.page)).observeSingleEvent(of: .value) { (snapshot) in
                     
                        
                        FirebaseVariables.ref.child("posts").child(key).observeSingleEvent(of: .value) { (snapshot) in
                            
                            
                            self.snapshotChildrenCount = Int(snapshot.childrenCount)
                        }
                        
                        
                        for questionChild in snapshot.children {
                            dataSnap = questionChild as? DataSnapshot
                            childFotoNesneleriDict = dataSnap?.value as! NSDictionary
                            
                            let photoId = dataSnap.key
                            self.photoUidArray.append(photoId)
                            
                            
                            self.userUid.append(key)
                            
                            let value = dataSnap.value as? NSDictionary
                            self.photoImageUrl.append(value!["anafoto"]! as! String)
                            
                            self.collectionView.insertItems(at:[IndexPath(row:self.photoImageUrl.count-1,section:0)])
                            
                            
                            self.itemsArray.append(value)
                            //insert the rows
                           // self.tableView.insertRows(at: [IndexPath(row:self.itemsArray.count-1,section:0)], with: UITableViewRowAnimation.automatic)
                            
                            
                            self.loading.stopAnimating()
                            
                            
                        }
                    }
                }
           
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                
            self.collectionView.reloadData()
            self.tableView.reloadData()
                }
            self.loading.stopAnimating()
            self.refresher.endRefreshing()
            
            self.filterButton.isUserInteractionEnabled = true
            self.filterResultView.isUserInteractionEnabled = true
            
        }) { (error) in
            
            self.showAlert(title: "", message: error.localizedDescription)
        }
        
        self.loading.stopAnimating()
        self.refresher.endRefreshing()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        
    }
 
    
    //collectionview kac tane cell i olucak
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return photoImageUrl.count
    }
    
    
    //COLLECTIONVIEW METODLARI
    
    // cell sayisi
    
    
    // cell yapilandirilmasi yani cell'ler hangi cell'e bagli oldugunu storyboardda verdigimiz id "Cell" ile belli ediyoruz
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // cell'in bir ProfileCell turunde oldugunu belirtiyoruz
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ProfileCell
        
     
        cell.itemImage.sd_setImage(with: URL(string: self.photoImageUrl[indexPath.row]), placeholderImage: UIImage(named: "foto"))
        
        
        
        //cell.confic(profilePicture: profilPhotoInCell, name: self.userInfo[0], mentionName: self.userInfo[1])
        
        cell.itemImage.layer.cornerRadius =  22
        cell.itemImage.clipsToBounds = true
        
       
        
        return cell
        
    }
    
    //burada her collectionView cell icin deger veriyoruz her satirda 3 cell olsun istiyoruz bunu da hesaplayip ekledik
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let cellWidth = (width - 30) / 3 // ekranın her satirinda 3 tane urun olmasi icin collecitonview cellerimizi 3 e boluyoruz boylece 3er tane ekleidk
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    
    //bir cell secilince bilgilerini gostermek icin postVC ye gidiyoruz
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        postPhotoUid.append(photoUidArray[indexPath.row])
        postUserUid.append(userUid[indexPath.row])
        
        
        let post = self.storyboard?.instantiateViewController(withIdentifier: "PostVC") as! PostVC
        self.navigationController?.pushViewController(post, animated: true)
    }
    
    
    
  
    
    //Cell yapilandirma metodu yani her cell in alicagi degerleri atiyoruz (foto vb.)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SearchCell
        
        var user:NSDictionary? = nil
        
        
        
        UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
            if self.searchController.isActive && self.searchController.searchBar.text != "" {
                
                user = self.filteredUsers[indexPath.row]
            }
            
            
            
            cell.urunBaslik.text = user?["baslik"] as? String
            
            //bu kullanici adi degiskenini sadece bkullanici adinin basina @ koymak icin olusturduk yoksa olmuyor
            
            if let fiyat = user?["fiyat"] as? String {
            
            cell.fiyatLbl.text = " \(fiyat) ₺"
            
            }else{
                cell.fiyatLbl.text = ""
                cell.urunBaslik.text = ""
            }
            
            if let photoUrl = user?["anafoto"] as? String {
                cell.photoCell.sd_setImage(with: URL(string: photoUrl), placeholderImage: UIImage(named: "foto"))
                
            }else {
                cell.photoCell.image = nil
                
            }
            
            
        })
        
        cell.photoCell.layer.cornerRadius =  16
        cell.photoCell.clipsToBounds = true
        
        return cell
    }
    
    //eger searchbar secili degilse itemsArray degilse filtered array akdar cell ekleyor searchbar secince filtlereme basliycak
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
        if searchController.isActive && searchController.searchBar.text != ""{
            
            return filteredUsers.count
        }
        
        return itemsArray.count
    }
    
    
    //searchbar a yazi yazinca tetiklenen metod
    func updateSearchResults(for searchController: UISearchController) {
        
        //filterContent ile urunlerimizi filtreleiyoruz
        filterContent(searchText: self.searchController.searchBar.text!)
        
    }
    
    
    
    //TO-DO : diger metodlarin big-o karmasiklik problemleri cozumlendi ancak bu filter metodunda n^3 maliyetli cozulmesi gerek
    //burada searchbar a girdigimiz deger ile herhangi bir urun varmi kontrol ediyoruz mesela süpürge yazınca um supurgeler listelenir
    func filterContent(searchText: String){
            
        self.filteredUsers.removeAll(keepingCapacity: false)
        self.photoUidArrayFiltered.removeAll(keepingCapacity: false)
        self.userUidArrayFiltered.removeAll(keepingCapacity: false)
        
        if searchText != "" {
        
        
        FirebaseVariables.ref.child("posts").observeSingleEvent(of: .value, with: { (snapshot) in
            var dataSnap:DataSnapshot!
            var dataSnap2:DataSnapshot!
            var childFotoNesneleriDict:NSDictionary!

            for questionChild in snapshot.children {
                dataSnap2 = questionChild as? DataSnapshot
                childFotoNesneleriDict = dataSnap2?.value as! NSDictionary

                for questionChild2 in dataSnap2.children {
                    dataSnap = questionChild2 as? DataSnapshot
                    let value = dataSnap.value as! NSDictionary

                    let sehirim = value["sehir"] as? String
                    
                    
                    if let baslik = value["baslik"] as? String {
                    
                    let fullName = baslik
                        let fullNameArr : [String] = fullName.components(separatedBy: " ")
                        
                    //kendi sehrimizdeki urunleri, bize ait olmayan urunleri (dataSnap2.key != FirebaseVariables.uid) ve urun basligina gore filtereleme yapiyoruz
                    
                    for item in fullNameArr {
                    
                        if item.lowercased() == searchText.lowercased() && self.myCity == sehirim && dataSnap2.key != FirebaseVariables.uid {
                        
                        self.filteredUsers.append(value)
                        self.userUidArrayFiltered.append(dataSnap2.key)
                        self.photoUidArrayFiltered.append(dataSnap.key)
                        self.tableView.reloadData()
                            
                            break
                    }
                    
                }
                }
                }
            }
       })
    }
        
        
        self.tableView.reloadData()
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        
        if photoUidArrayFiltered.canSupport(index: indexPath.row) && userUidArrayFiltered.canSupport(index: indexPath.row) {
            
                    postPhotoUid.append(photoUidArrayFiltered[indexPath.row])
                    postUserUid.append(userUidArrayFiltered[indexPath.row])
            
            
                    let post = self.storyboard?.instantiateViewController(withIdentifier: "PostVC") as! PostVC
                    self.navigationController?.pushViewController(post, animated: true)
        }
        
    }
   
    
    //Tarihe gore siralama butonlari
    
    @IBAction func last7Day_Action(_ sender: Any) {
        
        last14DaysButton.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        last30DaysButton.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        last7DaysBtn.isEnabled = false
        last14DaysButton.isEnabled = false
        last30DaysButton.isEnabled = false
        
        dateFilter = "Son 7 Gün"
        
        self.collectionView.isHidden = true
        let desiredTime = Date().timeIntervalSince1970 - 86400 * 7  //son 1 hafta (1 gun 86400 sn)
        
        if filterArray.isEmpty {
            
            fetchByDate(itemsArray: nil, desiredTime: desiredTime, city: self.myCity!, completion: { (control) in
                
                
                if control == nil {
                    
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Son 7 Gün", message: "bu kriterde bir ürün yok")
                    
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
            
        }else{
            fetchByDate(itemsArray: filterArray as? [NSDictionary], desiredTime: desiredTime, city: self.myCity!, completion: { (control) in
                
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Son 7 Gün", message: "bu kriterde bir ürün yok")
                    
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
        }
        
       
        showAllFilterInLabel(date: dateFilter, Category: categoryFilter, price: priceFilter)
   
    }
    
    @IBAction func last14Day_Action(_ sender: Any) {
        
        last7DaysBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        last30DaysButton.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        last7DaysBtn.isEnabled = false
        last14DaysButton.isEnabled = false
        last30DaysButton.isEnabled = false
        
        dateFilter = "Son 14 Gün"
        
       
        self.collectionView.isHidden = true
        let desiredTime = Date().timeIntervalSince1970 - 86400 * 14 //son 14 gun
        
        if filterArray.isEmpty {
            
            fetchByDate(itemsArray: nil, desiredTime: desiredTime, city: self.myCity!, completion: { (control) in
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Son 14 Gün", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
            })
            
        }else{
            
            fetchByDate(itemsArray: filterArray as? [NSDictionary], desiredTime: desiredTime, city: self.myCity!, completion: { (control) in
                
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Son 14 Gün", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
        }
        
       
        showAllFilterInLabel(date: dateFilter, Category: categoryFilter, price: priceFilter)
        
    }
    
    @IBAction func last1Month_Action(_ sender: Any) {
        
        last14DaysButton.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        last7DaysBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        last7DaysBtn.isEnabled = false
        last14DaysButton.isEnabled = false
        last30DaysButton.isEnabled = false
        
        dateFilter = "Son 30 Gün"
        
        self.collectionView.isHidden = true
        let desiredTime = Date().timeIntervalSince1970 - 86400 * 30 //son 30 gun
        
        if filterArray.isEmpty {
            
            fetchByDate(itemsArray: nil, desiredTime: desiredTime, city: self.myCity!, completion: { (control) in
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Son 30 Gün", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
            
        }else{
            
            fetchByDate(itemsArray: filterArray as? [NSDictionary], desiredTime: desiredTime, city: self.myCity!, completion: { (control) in
                
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Son 30 Gün", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
        }
        
        
        
        showAllFilterInLabel(date: dateFilter, Category: categoryFilter, price: priceFilter)
        
    }
    
    
    @IBAction func fetchPhoneCategory_Action(_ sender: Any) {
        
        evBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        evEsyasiBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        carBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        yedekParcaBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        evBtn.isEnabled = false
        evEsyasiBtn.isEnabled = false
        carBtn.isEnabled = false
        yedekParcaBtn.isEnabled = false
        telefonBtn.isEnabled = false
        
        
        categoryFilter = "Telefon Kategorisi"
        
        self.collectionView.isHidden = true
        
        if filterArray.isEmpty {
            
            
            
            fetchByCategory(itemsArray: nil, category: "telefon", city: self.myCity!, completion: { (control) in
                
                if control == nil {
                    
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "Bu kiterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
            
        }else{
            
            fetchByCategory(itemsArray: filterArray as? [NSDictionary], category: "telefon", city: self.myCity!, completion: { (control) in
                
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
        }
        
      
        
        showAllFilterInLabel(date: dateFilter, Category: categoryFilter, price: priceFilter)
        
        
    }
   

    
    @IBAction func fetchHomeCategory_Action(_ sender: Any) {
        
        
        telefonBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        evEsyasiBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        carBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        yedekParcaBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        telefonBtn.isEnabled = false
        evEsyasiBtn.isEnabled = false
        carBtn.isEnabled = false
        yedekParcaBtn.isEnabled = false
        evBtn.isEnabled = false
        
        categoryFilter = "Ev Kategorisi"
     
        
        self.collectionView.isHidden = true
        
        if filterArray.isEmpty {
            
            fetchByCategory(itemsArray: nil, category: "ev", city: self.myCity!, completion: { (control) in
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
            
        }else{
            
            fetchByCategory(itemsArray: filterArray as? [NSDictionary], category: "ev", city: self.myCity!, completion: { (control) in
                
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
        }
        
        
       
        
        showAllFilterInLabel(date: dateFilter, Category: categoryFilter, price: priceFilter)
        
    }
    
    
    
    
   
    @IBAction func fetchHouseGoodsCategory_Action(_ sender: Any) { //ev esyalari kategorisi
        
        telefonBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        evBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        carBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        yedekParcaBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        telefonBtn.isEnabled = false
        evBtn.isEnabled = false
        carBtn.isEnabled = false
        yedekParcaBtn.isEnabled = false
        evEsyasiBtn.isEnabled = false
        
        
        categoryFilter = "Ev Eşyaları Kategorisi"
        
        self.collectionView.isHidden = true
        
        if filterArray.isEmpty {
            
            fetchByCategory(itemsArray: nil, category: "ev eşyası", city: self.myCity!, completion: { (control) in
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
            
        }else{
            
            fetchByCategory(itemsArray: filterArray as? [NSDictionary], category: "ev eşyası", city: self.myCity!, completion: { (control) in
                
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
        }
        
        
        
        showAllFilterInLabel(date: dateFilter, Category: categoryFilter, price: priceFilter)
    
    }
    
    @IBAction func fetchSparePartCategory_Action(_ sender: Any) { //yedek parca filtreleme
        
        telefonBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        evBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        carBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        evEsyasiBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        telefonBtn.isEnabled = false
        evBtn.isEnabled = false
        carBtn.isEnabled = false
        evEsyasiBtn.isEnabled = false
        yedekParcaBtn.isEnabled = false
        
        categoryFilter = "Yedek Parça Kategorisi"
        
        self.collectionView.isHidden = true
        
        if filterArray.isEmpty {
            
            fetchByCategory(itemsArray: nil, category: "yedek parça", city: self.myCity!, completion: { (control) in
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
            
        }else{
            
            fetchByCategory(itemsArray: filterArray as? [NSDictionary], category: "yedek parça", city: self.myCity!, completion: { (control) in
                
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
        }
        
       
        
        showAllFilterInLabel(date: dateFilter, Category: categoryFilter, price: priceFilter)
        
    }
    
    @IBAction func fetchCarCategory_Action(_ sender: Any) {
        
       
        
        telefonBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        evBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        yedekParcaBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        evEsyasiBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        telefonBtn.isEnabled = false
        evBtn.isEnabled = false
        carBtn.isEnabled = false
        evEsyasiBtn.isEnabled = false
        yedekParcaBtn.isEnabled = false
        
        
        categoryFilter = "Araba Kategorisi"
        
        
        self.collectionView.isHidden = true
        
        if filterArray.isEmpty {
            
            fetchByCategory(itemsArray: nil, category: "araba", city: self.myCity!, completion: { (control) in
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
            
        }else{
            
            fetchByCategory(itemsArray: filterArray as? [NSDictionary], category: "araba", city: self.myCity!, completion: { (control) in
                
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                    
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            })
        }
        
        
        
        
        
        showAllFilterInLabel(date: dateFilter, Category: categoryFilter, price: priceFilter)
    }
    
    //fiyata gore siralama
    
    //artan siralama
    
    @IBAction func fetchAsAscending_Action(_ sender: Any) {

        azalanBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        azalanBtn.isEnabled = false
        artanBtn.isEnabled = false
        
        priceFilter = "Artan Sıralama"
     
        
        self.collectionView.isHidden = true
       
        if filterArray.isEmpty {
            
            
            //sorting 1 ise artan 2 ise azalan siralama yapiyoruz HelperFuncs.swift de
            
             fetchByPrice(itemsArray: nil , city: self.myCity!, sorting: 1) { (control) in
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            }
            
        }else{
            
             fetchByPrice(itemsArray: filterArray as? [NSDictionary] , city: self.myCity!, sorting: 1) { (control) in
                
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            }
        }
        
      
        
        showAllFilterInLabel(date: dateFilter, Category: categoryFilter, price: priceFilter)
        
        
    }
    
    //azalan siralama
    @IBAction func fetchAsDescending_Action(_ sender: Any) {
        
        
        artanBtn.setTitleColor(UIColor(red: 220.0 / 255.0, green: 137.0 / 255.0, blue: 137.0 / 255.0, alpha: 0.7), for: .normal)
        azalanBtn.isEnabled = false
        artanBtn.isEnabled = false
        
        
        priceFilter = "Azalan Sıralama"
        
        self.collectionView.isHidden = true
        
        if filterArray.isEmpty {
            
            fetchByPrice(itemsArray: nil , city: self.myCity!, sorting: 2) { (control) in
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            }
            
        }else{
            
            fetchByPrice(itemsArray: filterArray as? [NSDictionary] , city: self.myCity!, sorting: 2) { (control) in
                
                
                if control == nil {
                    self.clearOnlyArrayAndViews()
                    self.clearAllFilterInLabel()
                    self.showAlert(title: "Bulunamadı", message: "bu kriterde bir ürün yok")
                }else{
                    self.filterArray = control!
                    self.filter()
                }
                
                
                self.configureFilterResultVC(newArray: self.filterArray as! [NSDictionary])
                
            }
        }
        
        
      
        showAllFilterInLabel(date: dateFilter, Category: categoryFilter, price: priceFilter)
        
    }
    
    
    //tum filtreleri temizleme butonu
    @IBAction func clearAllFilter_Action(_ sender: Any) {
        
        
        last7DaysBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        last14DaysButton.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        last30DaysButton.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        evEsyasiBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        evBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        yedekParcaBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        carBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        telefonBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        artanBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        azalanBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        last7DaysBtn.isEnabled = true
        last14DaysButton.isEnabled = true
        last30DaysButton.isEnabled = true
        evBtn.isEnabled = true
        evEsyasiBtn.isEnabled = true
        yedekParcaBtn.isEnabled = true
        carBtn.isEnabled = true
        telefonBtn.isEnabled = true
        artanBtn.isEnabled = true
        azalanBtn.isEnabled = true
        
        
        dateFilter = ""
        priceFilter = ""
        categoryFilter = ""
        
        clearAllFilterInLabel()
        
        
         UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
        
        self.collectionView.isHidden = false
        })
        
        
        photoUidArrayF.removeAll(keepingCapacity: false)
        photoImageUrlF.removeAll(keepingCapacity: false)
        userUidF.removeAll(keepingCapacity: false)
        filterArray.removeAll(keepingCapacity: false)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "filtered"), object: nil)
    }
    
    func clearOnlyArrayAndViews(){
        
        
        
        last7DaysBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        last14DaysButton.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        last30DaysButton.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        evEsyasiBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        evBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        yedekParcaBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        carBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        telefonBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        artanBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        azalanBtn.setTitleColor(UIColor(red: 139.0 / 255.0, green: 3.0 / 255.0, blue: 3.0 / 255.0, alpha: 1), for: .normal)
        last7DaysBtn.isEnabled = true
        last14DaysButton.isEnabled = true
        last30DaysButton.isEnabled = true
        evBtn.isEnabled = true
        evEsyasiBtn.isEnabled = true
        yedekParcaBtn.isEnabled = true
        carBtn.isEnabled = true
        telefonBtn.isEnabled = true
        artanBtn.isEnabled = true
        azalanBtn.isEnabled = true
        
       
        dateFilter = ""
        priceFilter = ""
        categoryFilter = ""
        
        clearAllFilterInLabel()
        
        
        UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve, animations: {
            
            self.collectionView.isHidden = false
        })
        
        photoUidArrayF.removeAll(keepingCapacity: false)
        photoImageUrlF.removeAll(keepingCapacity: false)
        userUidF.removeAll(keepingCapacity: false)
        filterArray.removeAll(keepingCapacity: false)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "filtered"), object: nil)
        
        
    }
    
    
    func showAllFilterInLabel(date:String, Category:String, price:String){
        
      showFiltersTxt.text = "\(date) \n \(Category) \n \(priceFilter)"
        
    }
    
    func clearAllFilterInLabel(){
        
        showFiltersTxt.text = "\("") \n \("") \n \("")"
        
    }
    

    
    func configureFilterResultVC(newArray: [NSDictionary]){
        
        photoUidArrayF.removeAll(keepingCapacity: false)
        photoImageUrlF.removeAll(keepingCapacity: false)
        userUidF.removeAll(keepingCapacity: false)
        
        for item in newArray {
            photoUidArrayF.append(item["photoId"] as! String)
            photoImageUrlF.append(item["anafoto"] as! String)
            userUidF.append(item["userUid"] as! String)
        }
        
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "filtered"), object: nil)
        
    }
    
}
