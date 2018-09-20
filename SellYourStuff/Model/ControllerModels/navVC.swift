

import UIKit



//burada navigationControllerlarimiza tema oluşturduk ve navigation Controllerlarimizin class kismina bu sinifi ekledik

class navVC: UINavigationController {
    
    
    //butun navigationBar kokenli ViewControllerlara  bu temayi vericez
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // nav bar yazilari beyaz yaptik
        self.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor(red: 37.0 / 255.0, green: 79.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)]
        
         self.navigationBar.titleTextAttributes  = [NSAttributedStringKey.font: UIFont(name: "Roboto-Medium", size: 20)!]
        
        // nav bar buttonlarin rengini de beyaz
        self.navigationBar.tintColor = .darkGray
        
        // navbar arkaplan koyu mavi yaptik
        self.navigationBar.barTintColor = UIColor.white
        
        //saydamlık
        // disable translucent
        self.navigationBar.isTranslucent = false
    }
    
    
    // white status bar function
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default
    }

}


