//
//  IterableInAppManager.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit

@objc public class IterableInAppManager: NSObject {
    /**
     An array of action objects representing the actions that the user can take in response to the alert view
     */
    @objc public var actions: [String] = []

    /**
     Creates and shows a HTML InApp Notification with trackParameters, backgroundColor with callback handler
     
     - parameters:
        - htmlString:      The NSString containing the dialog HTML
        - trackParams:     The track params for the notification
        - callbackBlock:   The callback to send after a button on the notification is clicked
        - backgroundAlpha: The background alpha behind the notification
        - padding:         The padding around the notification
     */
    @objc public static func showIterableNotificationHTML(_ htmlString: String,
                                                          trackParams: IterableNotificationMetadata?,
                                                          callbackBlock: ITEActionBlock?,
                                                          backgroundAlpha: Double,
                                                          padding: UIEdgeInsets) {
        guard let rootViewController = getTopViewController() else {
            return
        }
        
        let baseNotification = IterableInAppHTMLViewController(data: htmlString)
        baseNotification.ITESetTrackParams(trackParams)
        baseNotification.ITESetCallback(callbackBlock)
        baseNotification.ITESetPadding(padding)

        rootViewController.definesPresentationContext = true
        baseNotification.view.backgroundColor = UIColor(white: 0, alpha: CGFloat(backgroundAlpha))
        baseNotification.modalPresentationStyle = .overCurrentContext

        rootViewController.present(baseNotification, animated: false)
    }
    
    /**
     Creates and shows a HTML InApp Notification; with callback handler
     
     - parameter htmlString:      The NSString containing the dialog HTML
     - parameter callbackBlock:   The callback to send after a button on the notification is clicked
     */
    @objc public static func showIterableNotificationHTML(_ htmlString:String, callbackBlock: ITEActionBlock?) {
        showIterableNotificationHTML(htmlString, trackParams: nil, callbackBlock: callbackBlock, backgroundAlpha: 0, padding: .zero)
    }
    
    /**
     Displays a iOS system style notification with two buttons
     
     - parameters:
        - title:           The NSDictionary containing the dialog options
        - body:            The notification message body
        - buttonLeft:      The text of the left button
        - buttonRight:     The text of the right button
        - callbackBlock:   The callback to send after a button on the notification is clicked
     
     - remark:            passes the string of the button clicked to the callbackBlock
     */
    @objc public static func showSystemNotification(_ title: String,
                                                    body: String,
                                                    buttonLeft: String?,
                                                    buttonRight: String?,
                                                    callbackBlock: ITEActionBlock?) {
        guard let rootViewController = getTopViewController() else {
            return
        }
        
        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        
        if let buttonLeft = buttonLeft {
            addAlertActionButton(alertController: alertController, keyString: buttonLeft, callbackBlock: callbackBlock)
        }
        if let buttonRight = buttonRight {
            addAlertActionButton(alertController: alertController, keyString: buttonRight, callbackBlock: callbackBlock)
        }
        
        rootViewController.show(alertController, sender: self)
    }
    
    
    /**
     Gets the next message from the payload
     
     - parameter payload:         The payload dictionary
     
     - returns: a Dictionary containing the InAppMessage parameters
     */
    @objc public static func getNextMessageFromPayload(_ payload: [AnyHashable : Any]) -> [AnyHashable : Any]? {
        guard let messageArray = payload[ITERABLE_IN_APP_MESSAGE] as? [[AnyHashable : Any]], messageArray.count > 0 else {
            return nil
        }
        return messageArray[0]
    }
    
    /**
     Gets the int value of the color from the payload
     
     - param payload:          the NSDictionary
     - param keyString:        the key to use to lookup the value in the payload dictionary
     
     - returns: the int color
     */
    @objc public static func getIntColorFromKey(_ payload: [AnyHashable : Any], keyString: String) -> Int {
        guard let colorString = payload[keyString] as? String, colorString.count > 0 else {
            return 0
        }
        
        var result: UInt64 = 0
        
        let scanner = Scanner(string: colorString)
        scanner.scanLocation = 1
        scanner.scanHexInt64(&result)
        
        return Int(result)
    }

    /**
     Parses the padding offsets from the payload
     
     - parameter payload:         the payload NSDictionary
     
     - returns: the UIEdgeInset
     */
    @objc public static func getPaddingFromPayload(_ payload: [AnyHashable : Any]?) -> UIEdgeInsets {
        guard let payload = payload else {
            return UIEdgeInsets.zero
        }

        var padding = UIEdgeInsets.zero
        if let topPadding = payload[PADDING_TOP] {
            padding.top = CGFloat(decodePadding(topPadding))
        }
        if let leftPadding = payload[PADDING_LEFT] {
            padding.left = CGFloat(decodePadding(leftPadding))
        }
        if let rightPadding = payload[PADDING_RIGHT] {
            padding.right = CGFloat(decodePadding(rightPadding))
        }
        if let bottomPadding = payload[PADDING_BOTTOM] {
            padding.bottom = CGFloat(decodePadding(bottomPadding))
        }
        
        return padding
    }
    
    /*!
     @method
     
     @abstract Gets the int value of the padding from the payload
     
     @param value          the value
     
     @return the padding integer
     
     @discussion Passes back -1 for Auto expanded padding
     */
    @objc public static func decodePadding(_ value: Any) -> Int {
        guard let dict = value as? [AnyHashable : Any] else {
            return 0
        }
        
        if let displayOption = dict[IN_APP_DISPLAY_OPTION] as? String, displayOption == IN_APP_AUTO_EXPAND {
            return -1
        } else {
            if let percentage = dict[IN_APP_PERCENTAGE] as? NSNumber {
                return percentage.intValue
            } else {
                return 0
            }
        }
    }
    
    static func getBackgroundAlpha(fromInAppSettings settings: [AnyHashable : Any]?) -> Double {
        guard let settings = settings else {
            return 0
        }

        if let number = settings[ITERABLE_IN_APP_BACKGROUND_ALPHA] as? NSNumber {
            return number.doubleValue
        } else {
            return 0
        }
    }
    
    private static func getTopViewController() -> UIViewController? {
        guard let rootViewController = IterableUtil.rootViewController else {
            return nil
        }
        var topViewController = rootViewController
        while (topViewController.presentedViewController != nil) {
            topViewController = topViewController.presentedViewController!
        }
        return topViewController
    }
    
    /**
     Creates and adds an alert action button to an alertController
     
     - parameter alertController:  The alert controller to add the button to
     - parameter keyString:        the text of the button
     - parameter callbackBlock:    the callback to send after a button on the notification is clicked
     
     - remarks:            passes the string of the button clicked to the callbackBlock
     */
    private static func addAlertActionButton(alertController: UIAlertController, keyString: String, callbackBlock: ITEActionBlock?) {
        let button = UIAlertAction(title: keyString, style: .default) { (action) in
            alertController.dismiss(animated: false)
            callbackBlock?(keyString)
        }
        alertController.addAction(button)
    }
    
    private static let PADDING_TOP = "top"
    private static let PADDING_LEFT = "left"
    private static let PADDING_BOTTOM = "bottom"
    private static let PADDING_RIGHT = "right"
    
    private static let IN_APP_DISPLAY_OPTION = "displayOption"
    private static let IN_APP_AUTO_EXPAND = "AutoExpand"
    private static let IN_APP_PERCENTAGE = "percentage"
}
