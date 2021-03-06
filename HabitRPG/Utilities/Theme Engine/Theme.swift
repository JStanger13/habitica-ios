//
//  Theme.swift
//  Habitica
//
//  Created by Phillip Thelen on 23.02.18.
//  Copyright © 2018 HabitRPG Inc. All rights reserved.
//

import UIKit

public protocol Theme {
    
    var contentBackgroundColor: UIColor { get }
    var windowBackgroundColor: UIColor { get }
    var backgroundTintColor: UIColor { get }
    var tintColor: UIColor { get }
    var separatorColor: UIColor { get }
    
    var primaryTextColor: UIColor { get }
    var secondaryTextColor: UIColor { get }

}

extension Theme {
    
    public var contentBackgroundColor: UIColor { return UIColor.white }
    public var windowBackgroundColor: UIColor { return UIColor.gray700() }
    public var backgroundTintColor: UIColor { return UIColor.purple300() }
    public var tintColor: UIColor { return UIColor.purple400() }
    public var separatorColor: UIColor { return UIColor.gray600() }
    
    public var primaryTextColor: UIColor { return UIColor.gray10() }
    public var secondaryTextColor: UIColor { return UIColor.gray100() }
    
    public func applyContentBackgroundColor(views: [UIView]) {
        views.forEach {
            $0.backgroundColor = contentBackgroundColor
        }
    }
    
}

@objc
class ObjcThemeWrapper: NSObject {
    
    @objc public static var contentBackgroundColor: UIColor { return ThemeService.shared.theme.contentBackgroundColor }
    @objc public static var windowBackgroundColor: UIColor { return ThemeService.shared.theme.windowBackgroundColor }
    @objc public static var backgroundTintColor: UIColor { return ThemeService.shared.theme.backgroundTintColor }
    @objc public static var tintColor: UIColor { return ThemeService.shared.theme.tintColor }
    
    @objc public static var primaryTextColor: UIColor { return ThemeService.shared.theme.primaryTextColor }
    @objc public static var secondaryTextColor: UIColor { return ThemeService.shared.theme.secondaryTextColor }
}
