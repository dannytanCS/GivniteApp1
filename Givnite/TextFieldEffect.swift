//
//  TextFieldEffect.swift
//  Givnite
//
//  Created by Lee SangJoon  on 7/2/16.
//  Copyright © 2016 Givnite. All rights reserved.
//

import Foundation
import UIKit
import TextFieldEffects

class ExampleTableViewController : UITableViewController {
    
    @IBOutlet private var textFields: [TextFieldEffects]!
    
    /**
     Set this value to true if you want to see all the "firstName"
     textFields prepopulated with the name "Raul" (for testing purposes)
     */
    let prefillTextField = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard prefillTextField == true else { return }
        
        _ = textFields.map { $0.text = "Raul" }
    }
}