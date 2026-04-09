import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Pridobi URL slike iz FCM payload-a
            guard let imageURLString = bestAttemptContent.userInfo["fcm_options"] as? [String: Any],
                  let urlString = imageURLString["image"] as? String,
                  let fileURL = URL(string: urlString) else {
                contentHandler(bestAttemptContent)
                return
            }
            
            // Prenos slike
            let task = URLSession.shared.downloadTask(with: fileURL) { (location, response, error) in
                if let location = location {
                    let tmpDirectory = NSTemporaryDirectory()
                    let tmpFile = "file://".appending(tmpDirectory).appending(fileURL.lastPathComponent)
                    let tmpUrl = URL(string: tmpFile)!
                    
                    do {
                        try FileManager.default.moveItem(at: location, to: tmpUrl)
                        let attachment = try UNNotificationAttachment(identifier: "", url: tmpUrl, options: nil)
                        bestAttemptContent.attachments = [attachment]
                    } catch {
                        print("Napaka pri pripenjanju slike: \(error)")
                    }
                }
                contentHandler(bestAttemptContent)
            }
            task.resume()
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
