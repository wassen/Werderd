//
//  WerderdType.swift
//  Werderd
//
//  Created by 浅山和宣 on 2018/03/09.
//  Copyright © 2018年 Kazuki Asayama. All rights reserved.
//

import Foundation

struct WerderdTypeModel {
    static var `default` = WerderdTypeModel()

    var types: [String] {
        didSet {
            NotificationCenter.default.post(
                name: Notification.Name("WerderdTypeModel_types"),
                object: self.types
            )
        }
    }

    init() {
        self.types = ["default"]
    }
}
