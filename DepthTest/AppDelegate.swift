//
//  AppDelegate.swift
//  DepthTest
//
//  Created by Emrah Gunduz on 8.09.2020.
//  Copyright © 2020 Synthesized Media Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  public var  window:         UIWindow?
  public var  viewController: ViewController?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Disable idle timer to keep screen light on
    UIApplication.shared.isIdleTimerDisabled = true

    // Set to default orientation
    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")

    // Set up window
    self.window = { () -> UIWindow in
      let window = UIWindow.init(frame: UIScreen.main.bounds)
      window.backgroundColor = UIColor.white
      window.makeKeyAndVisible()

      self.viewController = ViewController.init()
      self.viewController?.modalPresentationStyle = .fullScreen
      window.rootViewController = self.viewController

      return window
    }()

    return true
  }
}

