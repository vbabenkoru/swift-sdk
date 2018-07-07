//
//  NotificationService.swift
//  IterableAppExtensions
//
//  Created by Tapash Majumder on 6/8/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UserNotifications

@objc open class ITBNotificationServiceExtension: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    let test = TestFile()
    
    @objc override open func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        //IMPORTANT: need to add this to the documentation
        bestAttemptContent?.categoryIdentifier = getCategory(fromContent: request.content)

        guard let itblDictionary = request.content.userInfo[ITBConsts.Payload.metadata] as? [AnyHashable : Any] else {
            if let bestAttemptContent = bestAttemptContent {
                contentHandler(bestAttemptContent)
            }
            return
        }
        
        var contentHandlerCalled = false
        contentHandlerCalled = loadAttachment(itblDictionary: itblDictionary)
        
        if !contentHandlerCalled {
            if let bestAttemptContent = bestAttemptContent {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    @objc override open func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func loadAttachment(itblDictionary: [AnyHashable : Any]) -> Bool {
        guard let attachmentUrlString = itblDictionary[ITBConsts.Payload.attachmentUrl] as? String else {
            return false
        }
        guard let url = URL(string: attachmentUrlString) else {
            return false
        }
        
        
        let downloadTask = URLSession.shared.downloadTask(with: url, completionHandler: {[weak self] (location, response, error) in
            guard let strongSelf = self else {
                return
                
            }
            if error == nil, let response = response, let responseUrl = response.url, let location = location {
                let tempDirectoryUrl = FileManager.default.temporaryDirectory
                var attachmentIdString = UUID().uuidString + responseUrl.lastPathComponent
                if let suggestedFilename = response.suggestedFilename {
                    attachmentIdString = UUID().uuidString + suggestedFilename
                }
                var attachment: UNNotificationAttachment? = nil
                let tempFileUrl = tempDirectoryUrl.appendingPathComponent(attachmentIdString)
                do {
                    try FileManager.default.moveItem(at: location, to: tempFileUrl)
                    attachment = try UNNotificationAttachment(identifier: attachmentIdString, url: tempFileUrl, options: nil)
                }
                catch { /* TODO FileManager or attachment error */ }
                if let attachment = attachment, let bestAttemptContent = strongSelf.bestAttemptContent, let contentHandler = strongSelf.contentHandler {
                    bestAttemptContent.attachments.append(attachment)
                    contentHandler(bestAttemptContent)
                }
            }
            else { /* TODO handle download error */ }
        })
        downloadTask.resume()
        return true
    }
    
    private func getCategory(fromContent content: UNNotificationContent) -> String {
        if content.categoryIdentifier.count == 0 {
            guard let itblDictionary = content.userInfo[ITBConsts.Payload.metadata] as? [AnyHashable : Any] else {
                return ""
            }
            guard let messageId = itblDictionary[ITBConsts.Payload.messageId] as? String else {
                return ""
            }
            var actionButtons: [[AnyHashable : Any]] = []
            if let actionButtonsFromITBLPayload = itblDictionary[ITBConsts.Payload.actionButtons] as? [[AnyHashable : Any]] {
                actionButtons = actionButtonsFromITBLPayload
            } else {
                #if DEBUG
                if let actionButtonsFromUserInfo = content.userInfo[ITBConsts.Payload.actionButtons] as? [[AnyHashable : Any]] {
                    actionButtons = actionButtonsFromUserInfo
                }
                #endif
            }

            var notificationActions = [UNNotificationAction]()
            for actionButton in actionButtons {
                if let notificationAction = createNotificationActionButton(buttonDictionary: actionButton) {
                    notificationActions.append(notificationAction)
                }
            }
            
            messageCategory = UNNotificationCategory(identifier: messageId, actions: notificationActions, intentIdentifiers: [], options: [])
            if let messageCategory = messageCategory {
                UNUserNotificationCenter.current().getNotificationCategories {(categories) in
                    var newCategories = categories
                    newCategories.insert(messageCategory)
                    UNUserNotificationCenter.current().setNotificationCategories(newCategories)
                }
            }
            
            return messageId
        } else {
            return content.categoryIdentifier
        }
    }
    
    private func createNotificationActionButton(buttonDictionary: [AnyHashable : Any]) -> UNNotificationAction? {
        guard let identifier = buttonDictionary[ITBConsts.Button.identifier] as? String else {
            return nil
        }
        guard let title = buttonDictionary[ITBConsts.Button.title] as? String else {
            return nil
        }
        let buttonType = getButtonType(buttonDictionary: buttonDictionary)
        var openApp = true
        if let openAppFromDict = buttonDictionary[ITBConsts.Button.openApp] as? NSNumber {
            openApp = openAppFromDict.boolValue
        }
        var requiresUnlock = false
        if let requiresUnlockFromDict = buttonDictionary[ITBConsts.Button.requiresUnlock] as? NSNumber {
            requiresUnlock = requiresUnlockFromDict.boolValue
        }
        
        var actionOptions : UNNotificationActionOptions = []
        if buttonType == IterableButtonTypeDestructive {
            actionOptions.insert(.destructive)
        }
        
        if openApp {
            actionOptions.insert(.foreground)
        }
        
        if requiresUnlock || openApp {
            actionOptions.insert(.authenticationRequired)
        }
        
        if buttonType == IterableButtonTypeTextInput {
            let inputTitle = buttonDictionary[ITBConsts.Button.inputTitle] as? String ?? ""
            let inputPlaceholder = buttonDictionary[ITBConsts.Button.inputPlaceholder] as? String ?? ""
            
            return UNTextInputNotificationAction(identifier: identifier,
                                          title: title,
                                          options: actionOptions,
                                          textInputButtonTitle: inputTitle,
                                          textInputPlaceholder: inputPlaceholder)
        } else {
            return UNNotificationAction(identifier: identifier, title: title, options: actionOptions)
        }
    }
    
    private func getButtonType(buttonDictionary: [AnyHashable : Any]) -> String {
        guard let buttonType = buttonDictionary[ITBConsts.Button.type] as? String else {
            return IterableButtonTypeDefault
        }
        
        if buttonType == IterableButtonTypeTextInput || buttonType == IterableButtonTypeDestructive {
            return buttonType
        } else {
            return IterableButtonTypeDefault
        }
    }
    
    private var messageCategory: UNNotificationCategory?
    private let IterableButtonTypeDefault = "default"
    private let IterableButtonTypeDestructive = "destructive"
    private let IterableButtonTypeTextInput = "textInput"
}
