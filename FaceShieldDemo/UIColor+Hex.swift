//
//  UIColor+Hex.swift
//  FaceShieldDemo
//
//  Created by Konrad Feiler on 25.06.20.
//  Copyright © 2020 Konrad Feiler. All rights reserved.
//

import UIKit

extension UIColor {
    public convenience init?(hex: String) {
        let string = hex.prefix(1) == "#" ? String(hex.dropFirst()) : hex
        
        let start = string.index(string.startIndex, offsetBy: 0)
        let hexColor = String(string[start...])
        let r, g, b: CGFloat
        
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0
        
        if scanner.scanHexInt64(&hexNumber) {
            let a: CGFloat
            if hexColor.count == 8 {
                r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                a = CGFloat(hexNumber & 0x000000ff) / 255
            } else if hexColor.count == 6 {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
                a = 1.0
            } else {
                return nil
            }
            
            self.init(red: r, green: g, blue: b, alpha: a)
            return
        }
        
        return nil
    }
}
