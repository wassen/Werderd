//
//  Colors.swift
//  Werderd
//
//  Created by 浅山和宣 on 2018/03/15.
//  Copyright © 2018年 Kazuki Asayama. All rights reserved.
//

import Foundation
import UIKit

enum Colors: String {
    case cyan = "#15dab6"
    case orange = "#ffc410"
    case purple = "#a882f6"

    var color: UIColor {
        return UIColor(
            hex  : self.rawValue,
            alpha: 1.0
        )!
    }
}

private extension UIColor {
    convenience init?(hex: String, alpha: CGFloat) {
        let hex = hex.replacingOccurrences(of: "#", with: "")

        guard hex.utf8.count == 6 else {
            return nil
        }

//        hex[0...1] とできればすべて解決
        let hexArray = hex.map { String($0) }

        guard let redHex   = CGFloat.initialize(hex: hexArray[0] + hexArray[1]),
              let greenHex = CGFloat.initialize(hex: hexArray[2] + hexArray[3]),
              let blueHex  = CGFloat.initialize(hex: hexArray[4] + hexArray[5]) else {
            return nil
        }

        self.init(
            red  : redHex / 255,
            green: greenHex / 255,
            blue : blueHex / 255,
            alpha: alpha
        )
    }
}

private extension CGFloat {
    // Delegating initializers in structs are not marked with 'convenience'
    static func initialize(hex: String) -> CGFloat? {
        guard let intValue = UInt8(hex, radix: 16) else {
            return nil
        }

        return CGFloat(intValue)
    }
}
