//
//  DemoViewController.swift
//  
//
//  Created by hulilei on 2022/11/2.
//

import Foundation
import UIKit
import FTMobileAgent

class DemoViewController: UIViewController {
    
    func simulationView(){
        
        FTExtensionManager.shared().onCreateView("ViewA", loadTime: @123456)
        
        FTExtensionManager.shared().startView(withName: "ViewA")
        
        FTExtensionManager.shared().stopView()

    }
    
    func simulationAction(){
        FTExtensionManager.shared().addActionName("Custom_action_name", actionType: "click")
        
        FTExtensionManager.shared().addClickAction(withName: "Custom_action_name2")
    }
    
    func simulationError(){
        FTExtensionManager.shared().addError(withType: "ios_crash", message: "Error_Message", stack: "Error_Stack")
    }

}
