
import Foundation
import Chatto
import ChattoAdditions
import FirebaseDatabase
import SwiftyJSON

//bu classimizin amaci MesssagesModel dosyamizdaki mesajlasma ile ilgili modulleri birlestirip
//mesaj sayfamizin viewControllerina iletmek ve mesajlasma islemini yapmak


//burada NSObject turetmemizin nedeni = hatırlarsak helpers da NSObject'i kullanarak bi extension olusturup icine metodlar eklemistik iste o metodu kullanmak icin

class ChatItemsController: NSObject {
    
    var initialMessages = [ChatItemProtocol]() //burada mesaj ekrani acilir acilmaz eklenen mesajlar olucak
    var items = [ChatItemProtocol]() //buraya ise yukaridaki ilk mesajlar + yeni eklenen mesajlarda gelicek
    
    var loadMore = false //burada mesaj yuklenme olayini kontrol ediyoruz
    var userUID: String!//bu degeri dataSource ve messageViewControllerda aticaz bu diger kullanicinin id sini tutucak
    
    typealias completeLoading = () -> Void // loadPrevious metodunun completion tanimladik
    
    
    //**BURADA Kİ METODLARIMIZ OLUSTURDUGUMUZ DATASOURCE SINIFINDAN KULLANİLİYOR
    
    func loadIntoItemsArray(messagesNeeded: Int, moreToLoad: Bool){
        
        //burada items arrayimize yani tum mesajlarin bulundugu dizimize, ekran ilk acildiginda
        //gelen mesajlarin bulundugu arrayimiz olan initialMessages'dan mesajlari aktariyoruz
        //bu islem ekran acildiginda hep 1 kere gerceklesir
        
        //burada stride() metodu ile for dongusu mantigi ile ile dolasicaz
        //oncelikle from: kisminda dongumuzun basladigi degeri belirttik aslinda burada
        //direk initialMessages.count desek de olurdu cunku en basta items array'i bos
        //to: kisminda ise bittgi kisimda messagesNeeded parametresi ile cagrildigi yerden
        //min(initialMessages.count, 50) ile en az 50 olucak sekilde initial mesajin
        //degerini alıyoruz yani eger initialMessages.count>50 50 alicaz, >50 ise o degeri alicaz
        //ve bu aralikta donerek items arrayimizie ekleme yapiyoruz
        for index in stride(from: initialMessages.count - items.count, to: initialMessages.count - items.count - messagesNeeded, by: -1){
            
            self.items.insert(initialMessages[index - 1], at: 0)
            
            self.loadMore = moreToLoad //moreToLoad parametremiz cagrildigi yerden eger initialMessages.count > 50 dan yani eger daha fazla mesaj yuklenebilirse true kucukse false dondurur
        }
        
    }
    
    //Olusturdugumuz DataSource sinifinda cagrilmak uzere items arrayimize mesaj ekleme metodumuz
    func insertItem(message: ChatItemProtocol) {
        self.items.append(message)
    }
    
    //eski mesajlari yuklerken kullaniryoruz
    //burada Completion kullanmamızın nedeni cagrildigi yerde baska delegate cagirliyordu ve bu metodun onune geciyordu bizde bu metod bittikten
    //sonra yani mesajlar yuklendikten sonra cagrilsin diye ekleidk bunu
    
    func loadPrevious(Completion: @escaping completeLoading){
        
   
        
        //burada self.items.first!.uid diyerek son mesajin uid sini verip son eklenen mesajdan sonraki 52(51 tane olucak asagida silicez birini) mesaji aliyoruz
        Database.database().reference().child("User-messages").child(FirebaseVariables.uid).child(userUID).queryEnding(atValue: nil, childKey: self.items.first!.uid).queryLimited(toLast: 52).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            
            //burada rhs ve lhs ile mesajlarimizi zamanina gore diziye ekliyoruz
            var messages = Array(JSON(snapshot.value as Any).dictionaryValue.values).sorted(by: { (lhs, rhs) -> Bool in
                return lhs["date"].doubleValue < rhs["date"].doubleValue
            })
            
            //yukarida 52 mesaj yazdik ama zaten asagıda messages.removeLast() ile 1 tanesini siliyoruz
            messages.removeLast()
            self?.loadMore = messages.count > 50 //burada daha mesaj olup olmadigi kontrolunu duruma gore ayarliyoruz 50 den fazla ise daha mesaj var yani yuklenme olayi istenirse olabilir
            
            //burada Helper a ekledigimiz metod ile mesaj dizimizi ChatItem protocole ceviriyoruz
            let converted = self!.convertToChatItemProtocol(messages: messages)
            
            //burada da aldgimiz mesajlari items arrayimize ekliyoruz ancak bunu yaparken
            //min() metoduyla 50 yi gecmemesini sagliyoruz
            for index in stride(from: converted.count, to: converted.count - min(messages.count, 50), by: -1) {
                self?.items.insert(converted[index - 1], at: 0)
            }
            
            //completion ile datasourcede cagrildigi yerde islem yapiyor pagination ile ilgili
            Completion()
            
            //eger yuklenen mesajlar icinde foto varsa bunu helperdaki parseURLs() metodumuzla verdigimiz url deki fotoya cevirip yukleriz
            messages.filter({ (message) -> Bool in
                return message["type"].stringValue == PhotoModel.chatItemType
            }).forEach({ (message) in
                
                self?.parseURLs(UID_URL: (key: message["uid"].stringValue, value: message["image"].stringValue))
            })
            
        })
        
        
    }
    //burada eski mesajlari silmek icin eski yuklenen mesajlar eger biz yeni mesaja donersek yer kaplamasın diye siliyoruz
    func adjustWindow() {
        
        self.items.removeFirst(200)
        self.loadMore = true //ve burada eger tekrar silnen mesajlar yuklenebilsin diye true yaptik
        
    }
}

