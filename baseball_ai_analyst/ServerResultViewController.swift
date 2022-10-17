//
//  ServerResultViewController.swift
//  baseball_ai_analyst
//
//  Created by Admin on 2022/10/4.
//

import Foundation
import UIKit

class SecondViewController: UIViewController {
    var rpm:String?
    @IBOutlet weak var labelRPM: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.labelRPM.text = rpm
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func finish(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
