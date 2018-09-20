

import UIKit
import Chatto
import ChattoAdditions
import FirebaseAuth
import FirebaseDatabaseUI //
import SwiftyJSON
import Kingfisher
import FirebaseStorage

//burada uygulamamiza Kingfisher yuklememizin amaci data yi fotoya ceviricez


//Bu sinif mesaj atma ekraninin controleridir ancak herhangi bir tasarim ekraniyla baglantisi yok yani mainStoryBoardda tasarimi yok chatto kutuphanesinin ozelligi ve  decorator datasource da olusturdugumuz mesajlasma ile ilgili olaylari nesneleri ile eriserek bu controllerda gerceklestiriyoruz
class ChatLogController: BaseChatViewController, FUICollectionDelegate {
    
    var presenter: BasicChatInputBarPresenter!
    var decorator = Decorator()
    var dataSource: DataSource!
    var userUID = String()
    var messagesArray: FUIArray!
    
    override func createPresenterBuilders() -> [ChatItemType : [ChatItemPresenterBuilderProtocol]] {
        
        let textMessageBuilder = TextMessagePresenterBuilder(viewModelBuilder: TextBuilder(), interactionHandler: TextHandler())
        let photoPresenterBuilder = PhotoMessagePresenterBuilder(viewModelBuilder: PhotoBuilder(), interactionHandler: PhotoHandler())
        
        textMessageBuilder.baseMessageStyle = Avatar() //mesaja avatar eklemek icin olusturdumuz avatar sınıfına eşitledik
        photoPresenterBuilder.baseCellStyle = Avatar()
        
        return [TextModel.chatItemType : [textMessageBuilder],
                PhotoModel.chatItemType: [photoPresenterBuilder],
                
                //projemize hazir ekledigimiz TimeStamp icindeki dosyalarini kullanmaya basladik
            //bunun ayrintili kullanimi Decorator.swift de...  TimeStamp amaci mesajlarin tarihleini gostermek mesela mesaji sola kaydırınca tarihini gosterir yada hangi gun hangi mesaj oldugunu
            TimeSeparatorModel.chatItemType: [TimeSeparatorPresenterBuilder()],
            
            //projemize hazir ekledimiz sendingstatus icindeki dosyalari kullanmaya basladik
            //bunun ayrintili kullanimi Decorator.swift de...  SendingStatusModel kullanim amaci
            //mesaj gonderilirken altında "sending" gibi uyarı mesaji yazdırır
            SendingStatusModel.chatItemType: [SendingStatusPresenterBuilder()]
            
        ]
    }
    
    //mesajlasma alani ile ilgili gorsel alani duzenliyoruz
    //ve asagida onemli bir kismanda ise chatInputItems da handleSend() ve handlePhoto() ile
    //ilgili butonlara basinca photo veya text message gonderm olaylarini ekledik
    override func createChatInputView() -> UIView {
        let inputBar = ChatInputBar.loadNib()
        var appearance = ChatInputBarAppearance()
        appearance.sendButtonAppearance.title = "Send"
        appearance.textInputAppearance.placeholderText = "Type a message"
        self.presenter = BasicChatInputBarPresenter(chatInputBar: inputBar, chatInputItems: [handleSend(), handlePhoto()], chatInputBarAppearance: appearance)
        return inputBar
    }
    
    //burada text mesaji gonderme icin mesaja ozel uid olusturma tarihi alma vb islemler yapilir asagida olusturmuz sendOnlineTextMessage() metodu ile mesaj gonderilir ve firebase e kaydedilir
    
    func handleSend() -> TextChatInputItem {
        
        let item = TextChatInputItem()
        
        item.textInputHandler = { [weak self] text in
            
            let date = Date()
            let double = Date.timeIntervalSinceReferenceDate
            let senderId = FirebaseVariables.uid
            
            //burada hem kullanici uid mizi hemde mesajin olusturuldugu tarihi kullanarak mesaja ozel bir uid olusturduk
            let messageUID = ("\(double)" + senderId).replacingOccurrences(of: ".", with: "")
            
            //burada status .sending yaptik yuklenince burada cagırdımız sendOnlineTextMessage
            //metodu icindeki updateTextMessage() metodu cagrilir ve .success olur
            
            let message = MessageModel(uid: messageUID, senderId: senderId, type: TextModel.chatItemType, isIncoming: false, date: date, status: .sending)
            let textMessage = TextModel(messageModel: message, text: text)
            self?.dataSource.addMessage(message: textMessage)
            self?.sendOnlineTextMessage(text: text, uid: messageUID, double: double, senderId: senderId)
            
        }
        return item
    }
    
    
        //burada photo mesaji gonderme icin mesaja ozel uid olusturma tarihi alma vb islemler yapilir asagida olusturmuz uploadToStorage() metodu ile photo gonderilir ve firebase stroage e kaydedilir
    func handlePhoto() -> PhotosChatInputItem {
        
        
        let item = PhotosChatInputItem(presentingController: self)
        item.photoInputHandler = { [weak self] photo in
            
            let date = Date()
            let double = date.timeIntervalSinceReferenceDate
            let senderId = FirebaseVariables.uid
            
            
            //burada hem kullanici uid mizi hemde mesajin olusturuldugu tarihi kullanarak mesaja ozel bir uid olusturduk
            let messageUID = ("\(double)" + senderId).replacingOccurrences(of: ".", with: "")
            
            let message = MessageModel(uid: messageUID, senderId: senderId, type: PhotoModel.chatItemType, isIncoming: false, date: date, status: .sending)
            let photoMessage = PhotoModel(messageModel: message, imageSize: photo.size, image: photo)
            self?.dataSource.addMessage(message: photoMessage)
            self?.uploadToStorage(photo: photoMessage)
            
        }
        
        return item
        
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.chatDataSource = self.dataSource
        self.chatItemsDecorator = self.decorator
        self.constants.preferredMaxMessageCount = 300 //en fazla yuklenecek mesaj sayisi
        self.messagesArray.observeQuery()
        self.messagesArray.delegate = self
    }
    
    
    
    //Text messagemize bu metod ile firebase'e kaydediyoruz
    func sendOnlineTextMessage(text: String, uid: String, double: Double, senderId: String) {
        let message = ["text": text, "uid": uid, "date": double, "senderId": senderId, "status": "success", "type": TextModel.chatItemType] as [String : Any]
        let childUpdates = ["User-messages/\(senderId)/\(self.userUID)/\(uid)": message,
                            "User-messages/\(self.userUID)/\(senderId)/\(uid)": message,
                            "users/\(FirebaseVariables.uid)/Contacts/\(self.userUID)/lastMessage": message,
                            "users/\(self.userUID)/Contacts/\(FirebaseVariables.uid)/lastMessage": message,
                            ]
        
        Database.database().reference().updateChildValues(childUpdates) { [weak self] (error, _) in
            
            if error != nil {
                
                self?.dataSource.updateTextMessage(uid: uid, status: .sending)
                return
            }
            self?.dataSource.updateTextMessage(uid: uid, status: .success)
            
        }
        
    }
    
    
    //Photom messagemizdaki fotomuzu bu metod ile firebase storage e kaydediyoruz
    //asagidaki metod ile de bu fotonun url ve diger bilgilerini firebase'e kaydediyoruz
    func uploadToStorage(photo: PhotoModel) {
        
        let imageName = photo.uid
        let storage = Storage.storage().reference().child("images").child(imageName)
        
        let data = UIImageJPEGRepresentation(photo.image, 0.10)
        _ = storage.putData(data!, metadata: nil){ [weak self] (metadata, error) in
            
            
            
            
            if (error == nil){
                
                
                storage.downloadURL(completion: { (url, error) in
                    if error == nil && url != nil {
                        
                        
                        if let imageURL = url?.absoluteString {
                            
                            self?.sendOnlineImageMessage(photoMessage: photo, imageURL: imageURL)
                        } else {
                            self?.dataSource.updatePhotoMessage(uid: photo.uid, status: .sending)
                        }
                    }
        })
        
    }
        }
    }
    
    //photo mesajin url ve diger bilgilerini bu metod ile firebase'e kaydediyoruz
    func sendOnlineImageMessage(photoMessage: PhotoModel, imageURL: String) {
        
        
        let message = ["image": imageURL, "uid": photoMessage.uid, "date": photoMessage.date.timeIntervalSinceReferenceDate, "senderId": photoMessage.senderId, "status": "success", "type": PhotoModel.chatItemType] as [String : Any]
        
        let childUpdates = ["User-messages/\(photoMessage.senderId)/\(self.userUID)/\(photoMessage.uid)": message,
                            "User-messages/\(self.userUID)/\(photoMessage.senderId)/\(photoMessage.uid)": message,
                            "users/\(FirebaseVariables.uid)/Contacts/\(self.userUID)/lastMessage": message,
                            "users/\(self.userUID)/Contacts/\(FirebaseVariables.uid)/lastMessage": message,
                            ]
        
        Database.database().reference().updateChildValues(childUpdates) { [weak self] (error, _) in
            
            if error != nil {
                
                self?.dataSource.updatePhotoMessage(uid: photoMessage.uid, status: .sending)
                return
            }
            self?.dataSource.updatePhotoMessage(uid: photoMessage.uid, status: .success)
        }
    }
    
  
}


//burada FUI metodlarini ve table view metodlarini yazdık


extension ChatLogController{
    
    //burada didAdd kullanmamızın amacı diğer kullacinin yazdigi mesajlari ekrana getirmek icin hatirlarsak baska siniftada FUI sinifi ve didadd kullanmistik
    
    //burada  metodu var bu yukaridaki contantc dizimizde (ekleme silme)
    //vb. olaylar olunca ilgili metod calisir
    func array(_ array: FUICollection, didAdd object: Any, at index: UInt) {
        let message = JSON((object as! DataSnapshot).value as Any)
        let senderId = message["senderId"].stringValue
        let type = message["type"].stringValue
        let contains = self.dataSource.controller.items.contains { (collectionViewMessage) -> Bool in
            return collectionViewMessage.uid == message["uid"].stringValue
        }
        
        if contains == false {
            
            
            let model = MessageModel(uid: message["uid"].stringValue, senderId: senderId, type: type, isIncoming: senderId == FirebaseVariables.uid ? false : true, date: Date(timeIntervalSinceReferenceDate: message["date"].doubleValue), status: message["status"] == "success" ? MessageStatus.success : MessageStatus.sending)
            
            //eger nesaj text ise
            if type == TextModel.chatItemType {
                let textMessage = TextModel(messageModel: model, text: message["text"].stringValue)
                self.dataSource.addMessage(message: textMessage)
                
                //eger foto ise KingfisherManager ile data olan resmi resim formatina ceiviyoruz
                
            } else if type == PhotoModel.chatItemType {
                
                KingfisherManager.shared.retrieveImage(with: URL(string: message["image"].stringValue)!, options: nil, progressBlock: nil, completionHandler: { [weak self] (image, error, _, _) in
                    
                    if error != nil {
                        self?.showAlert(title: "",message: "error receiving image from friend")
                    } else {
                        
                        let photoMessage = PhotoModel(messageModel: model, imageSize: image!.size, image: image!)
                        self?.dataSource.addMessage(message: photoMessage)
                    }
                })
                
                
            }
            
            
            
        }
        
        
    }
    
    
}


