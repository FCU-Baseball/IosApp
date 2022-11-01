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
    var runtime:Float?
    @IBOutlet weak var labelRPM: UILabel!
    @IBOutlet weak var labelRuntime: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.labelRPM.text =  "\(String(describing: rpm))"
        self.labelRuntime.text = "\(String(describing: runtime))"
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func finish(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
