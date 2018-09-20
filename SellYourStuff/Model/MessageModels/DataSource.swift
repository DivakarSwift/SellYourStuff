
import Foundation
import Chatto
import ChattoAdditions

//sinifimizi ChatDataSourceProtocol dan ekledik ve bazi metod ve degiskenleri de ekledik
class DataSource: ChatDataSourceProtocol {
    
    
    weak var delegate: ChatDataSourceDelegateProtocol? //bunu weak yapmamizin nedeni bellek icin cunku asagida deinit metodundaki islemlerimizi calistiricaz
    
    var controller = ChatItemsController()
    var currentlyLoading = false
    
    init(initialMessages: [ChatItemProtocol], uid: String){
        
        self.controller.initialMessages = initialMessages
        self.controller.userUID = uid
        //burada mesaj eklerken initialMessages daki mesajlarin sayisini bilmedigimiz icin
        //icinden sadece en fazla 50 sini alip bu metodlar controllerdeki items arrayine ekliyoruz
        
        self.controller.loadIntoItemsArray(messagesNeeded: min(initialMessages.count, 50), moreToLoad: initialMessages.count > 50)
        
        
        //Burada notificationCenter kullanarak helper sifindan parseUrl() metodu calisinca
        //"updateImage" id si ile burasi tetiklenecek
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoadingPhoto), name: NSNotification.Name(rawValue: "updateImage"), object: nil)
        
        
    }
    
    //yukarida notification da cagirdigimiz metod
    @objc func updateLoadingPhoto(notification: Notification){
        
        let info = notification.userInfo as! [String:Any]
        let image = info["image"] as! UIImage
        let uid = info["uid"] as! String
        
        //asagida controller.items.index ile mesajlari geziyoruz ve bizim notification a
        //ait olan photoMesaji buluyoruz bunu mesaj.uid ile yapiyoruz
        //daha sonra photoModel a dondurup items arrayimize ekliyoruz
        
        //burada index where ile bi dongu olusturuluyor ve en dongu bitince  { } icindeki komutuda kesin isliyor yani else gibi degil
        if let index = self.controller.items.index(where: { (message) -> Bool in
            return message.uid == uid
        }) {
            let item = self.controller.items[index] as! PhotoModel
            let model = MessageModel(uid: item.uid, senderId: item.senderId, type: item.type, isIncoming: item.isIncoming, date: item.date, status: item.status)
            let photoMessage = PhotoModel(messageModel: model, imageSize: image.size, image: image)
            
            self.controller.items[index] = photoMessage
            self.delegate?.chatDataSourceDidUpdate(self)
            
        }
        
    }
    
    
    var chatItems: [ChatItemProtocol] {
        return controller.items
    }
    
    var hasMoreNext: Bool {
        
        return false
    }
    
    //eger bu deger true ise  asagidaki loadPrevious() metodu tetiklenir (chatto ile ilgili bi durum)
    var hasMorePrevious: Bool {
        return controller.loadMore
    }
    
    //bu metod yukaridaki hasMorePrevious proterty si true olunca calisir
    func loadPrevious() {
        
        //burada completion seklinde olan loadPrevious() metodunu cagirdik completion yapmamizin nedeni mesajlar yuklendikten sonra
        //delegate ve pagination olsun diye
        
        if currentlyLoading == false {
            
            currentlyLoading = true //ve burada yuklenme oldugundan true yapiyoruz
            controller.loadPrevious {
                self.delegate?.chatDataSourceDidUpdate(self, updateType: .firstLoad)
                self.currentlyLoading = false //yuklenme bittgiinen tekrar falsa yapiyoruz
            }
        }
        
    }
    
    func loadNext() {
        
    }
    
    //kendi olusturdugumuz bir metod mesaj eklemek icin kullaniyoruz
    //burada da controller da olusturdugumuz dizimize mesaj ekleme metodunu cagirioruz ve ekliyoruz
    func addMessage(message: ChatItemProtocol) {
        self.controller.insertItem(message: message)
        self.delegate?.chatDataSourceDidUpdate(self)
    }
    
    
    //kendi olusturdugumuz bir metod yeni bir mesaj eklenince bu metod calisir ve controller.items
    //sizimize bu degeri ekler
    func updateTextMessage(uid: String, status:MessageStatus){
        if let index = self.controller.items.index(where: { (message) -> Bool in
            
            return message.uid == uid //burada index degerine eklenen mesajin uid si ataniyor
            //ve daha sonra bu uid ile asagidaki islemler yapiliyor
            
        }){
            
            //burada passByReferance ile burada deigstirdimiz deger aynı zamanda ChatItemsController daki item dizisindeki mesajlarda da degisir
            let message = self.controller.items[index] as! TextModel
            message.status = status
            self.delegate?.chatDataSourceDidUpdate(self)
        }
    }
    
    
    //kendi olusturdugumuz bir metod yeni bir photo eklenince bu metod calisir ve controller.items
    //dizimize bu degeri ekler
    func updatePhotoMessage(uid: String, status: MessageStatus) {
        if let index = self.controller.items.index(where: { (message) -> Bool in
            return message.uid == uid//burada index degerine eklenen mesajin uid si ataniyor
            //ve daha sonra bu uid ile asagidaki islemler yapiliyor
        }) {
            //burada passByReferance ile burada deigstirdimiz deger aynı zamanda ChatItemsController daki item dizisindeki mesajlarda da degisir
            
            let message = self.controller.items[index] as! PhotoModel
            message.status = status
            self.delegate?.chatDataSourceDidUpdate(self)
            
        }
    }
  
    
    func adjustNumberOfMessages(preferredMaxCount: Int?, focusPosition: Double, completion: (Bool) -> Void) {
        
        //burada ekran 0.9 altına inerse yani paginationumuzu mesajlarimizi yine en sona kaydırırsak calisir
        if focusPosition > 0.9 {
            
            //burada tekrar ekranimizi basa indirdik (eski mesajlari yukledikten sonra)
            //bu durumda adjustWindow() metodu ile eski yuklenen mesajlari silmek icin cagiriyoruz
            self.controller.adjustWindow()
            completion(true)
        } else {
            completion(false)
        }
        
    }
    
    //ve en son observe sildik
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "updateImage"), object: nil)
    }
    
}

