//
//  AppDelegate.swift
//  
//
//  Created by hulilei on 2022/10/25.
//

import Foundation
import FTMobileAgent

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let mobileConfig = FTMobileConfig.init(metricsUrl: "YOUR URL")
        mobileConfig.enableSDKDebugLog = true
        mobileConfig.xDataKitUUID = "Custom_xDataKitUUID"
        mobileConfig.env = .common
        mobileConfig.globalContext = {"CustomKey":"CustomValue"}
        FTMobileAgent.start(withConfigOptions: mobileConfig)
        
        let rumConfig = FTRumConfig.init(appid: "YOUR APP ID")
        rumConfig.samplerate = 50
        rumConfig.enableTraceUserView = true
        rumConfig.enableTraceUserAction = true
        rumConfig.enableTraceUserResource = true
        rumConfig.enableTrackAppCrash = true
        rumConfig.errorMonitorType = .all
        rumConfig.enableTrackAppANR = true
        rumConfig.enableTrackAppFreeze = true
        return true
    }

}

