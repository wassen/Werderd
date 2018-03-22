//
// Created by 浅山和宣 on 2018/03/23.
// Copyright (c) 2018 Kazuki Asayama. All rights reserved.
//

import UIKit

extension UINavigationController {
    static func `default`(rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.navigationBar.barTintColor = .main
        navigationController.navigationBar.isTranslucent = false
        let textAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white
        ]
        navigationController.navigationBar.titleTextAttributes = textAttributes

        return navigationController
    }
}
