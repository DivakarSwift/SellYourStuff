
/*
 
 //projemize hazir ekledigimiz TimeStamp icindeki dosyalarini kullanmaya basladik
 //bu TimeStamp amaci mesajlarin tarihleini gostermek mesela mesaji sola kaydırınca tarihini gosterir yada hangi gun hangi mesaj oldugunu
 */


import Foundation
import UIKit
import Chatto

class TimeSeparatorModel: ChatItemProtocol {
    let uid: String
    let type: String = TimeSeparatorModel.chatItemType
    let date: String

    static var chatItemType: ChatItemType {
        return "TimeSeparatorModel"
    }

    init(uid: String, date: String) {
        self.date = date
        self.uid = uid
    }
}

extension Date {
    // Have a time stamp formatter to avoid keep creating new ones. This improves performance
    private static let weekdayAndDateStampDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "tr_TR")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "EEEE, MMM dd yyyy" // "Monday, Mar 7 2016"
        return dateFormatter
    }()

    func toWeekDayAndDateString() -> String {
        return Date.weekdayAndDateStampDateFormatter.string(from: self)
    }
}
