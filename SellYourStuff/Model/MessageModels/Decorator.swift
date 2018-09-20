

import Foundation
import Chatto
import ChattoAdditions

class Decorator: ChatItemsDecoratorProtocol {
   
    
    //ChatItemsDecoratorProtocol protocolune ait bu metodu override ettik
    //burada mesajlarimizi adi ustunde decor ediyoruz yani onlara ozellikler ekliyoruz
    //mesela takvim timeStamp ile mesaj tarihi, avatar fotosu vb. zaten asagida acikladim
    func decorateItems(_ chatItems: [ChatItemProtocol]) -> [DecoratedChatItem] {
        
        var decoratedItems = [DecoratedChatItem]()
        
        let calender = Calendar.current //mesajlarin atildigi tarihleri ve yukarida mesaj gununu gostermek icin ekledik daha sonra bunu stamp modelimizde kullanicaz
        
         //burada decoratedItems seklide mesajlara (index,item) seklinde erismek icin enumatered kullandik
        for(index, item) in chatItems.enumerated() {
            var addTimeStamp = false //yukarida gun yazilicak durumlari kontrol etmek icin kullandik (her mesajın ustune yazmasın sadece gün gün yukarida yazsin onu kontrol edicez)
            
            var showAvatar = false //bu deigskeni mesajda avatar resminin gosterilecegi durumlar icin ekledim bu kontrolu yapmazsak
            //her mesaja avatar ekler ve kotu goruntu olur bu kontrol ile sadece son mesaja yada diger kullanici mesaj atarsa
            //o arada ikisinede gibi durumlarda mesaja avatar koyucaz
            
             //next message ile sonra bir mesaj var mi diye kontrol ediyoruz varsa ona da bosluk vericez, avatar eklicez
            let nextMessage: ChatItemProtocol? = (index + 1 < chatItems.count) ? chatItems[index + 1] : nil
            
             //suan bulundugumuz indexteki mesajin 1 sonraki mesajina eristik
            let previousMessage: ChatItemProtocol? = (index > 0) ? chatItems[index - 1] : nil
            
            
            //ve burada da bu previosMessage yani suanki mesajin bi onceki mesaji ve suanki mesaj ayni gunde mi atilmis bunu kontrol ediyoruz ayri gunlerde ise addTimeStamp true diyicez ve asagilarda bunun ustunde farkli gunlerde oldugu icin gun eklenicek
            if let previousMessage = previousMessage as? MessageModelProtocol {
                
                addTimeStamp = !calender.isDate((item as! MessageModelProtocol).date, inSameDayAs: previousMessage.date)
            } else{
                addTimeStamp = true
            }
            
            //burada ardisik mesajlar farkli kisilerden ise avatar gosteriyoruz yoksa ayni kisiden oldugundan gene gene gostermemek icin avatar eklemicez (asagilarda)
            if let nextMessage = nextMessage as?  MessageModelProtocol {
                
                showAvatar = (item as! MessageModelProtocol).senderId != nextMessage.senderId
            }else{
                showAvatar = true
            }
            
            //yukarda kontrolumuz sonucu farkli gunlerde olan mesajlarin ust kısmına gun bilgisini ekliyoruz
            if addTimeStamp == true {
                let timeStampSeperatorModel = TimeSeparatorModel(uid: UUID().uuidString, date: (item as! MessageModelProtocol).date.toWeekDayAndDateString())
                
                decoratedItems.append(DecoratedChatItem(chatItem: timeStampSeperatorModel, decorationAttributes: nil))
            }
            
            let bottomMargin = separationAfterItem(current: item, next: nextMessage)
            
            //burada da yukarida olusturdumuz ozellikleri decoratedItem a ekliyoruz
            let decoratedItem = DecoratedChatItem(chatItem: item, decorationAttributes: ChatItemDecorationAttributes(bottomMargin: bottomMargin, messageDecorationAttributes: BaseMessageDecorationAttributes(canShowFailedIcon: true, isShowingTail: false, isShowingAvatar: showAvatar, isShowingSelectionIndicator: false, isSelected: false)))
            decoratedItems.append(decoratedItem)
       
            //burada da mesajimiz success olana kadar ekledigimiz sendingStatus modeli devreye gidiyor ve mesajimizda "sending" yazisi cikiyor
            if let status = (item as? MessageModelProtocol)?.status, status != .success {
                
                let statusModel = SendingStatusModel(uid: UUID().uuidString, status: status)
                decoratedItems.append(DecoratedChatItem(chatItem: statusModel, decorationAttributes: nil))
            }
        }
        return decoratedItems
    }
    
    
    //bu metod ile iki kullanici arasindaki mesajlarda alt alta mesajlar ayni kullanicininca bu iki mesaj arasinda 3
    //değilse yani farklı kullanicilara ait ise boslugu 10 vericez
    //ayrica herhangi bir mesaj basarisiz olursa da 10 bosluk vericez
    func separationAfterItem(current: ChatItemProtocol?, next: ChatItemProtocol?) -> CGFloat {
        guard let next = next else {return 0}
        
        let currentMessage = current as? MessageModelProtocol
        let nextMessage = next as? MessageModelProtocol
        
        
        //eger mesaj basarisizsa 10 px bosluk bırak alttaki mesaja
        if let status = currentMessage?.status, status != .success{
            
            return 10
        }
            
            //eger id ler ayni degilse yani farkli iki mesaj alt altaysa 10 px bosluk degilse ayni kisinin ayni mesajlariysa 3 px bosluk
        else if currentMessage?.senderId != nextMessage?.senderId {
            return 10
        } else {
            return 3
        }
    }
    
    
    
}












