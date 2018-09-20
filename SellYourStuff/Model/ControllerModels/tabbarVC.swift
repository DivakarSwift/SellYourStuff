

import UIKit



//burada tabbarimiza tema oluşturduk ve tabbarimizin class kismina bu sinifi ekledik

class tabbarVC: UITabBarController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // color of item
        self.tabBar.tintColor = UIColor.black
        
        //fb mavisi :)
        //self.tabBar.tintColor = UIColor(red: 37.0 / 255.0, green: 79.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)
        
        
        self.tabBar.unselectedItemTintColor = UIColor.gray
        
        
        // disable translucent
        self.tabBar.isTranslucent = false
        
      
        
    }
    
  
    
}
