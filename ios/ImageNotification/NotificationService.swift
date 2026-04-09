import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Extract image URL from FCM payload
            // FCM standard: fcm_options.image
            // Custom: imageUrl in data
            guard let imageURLString = bestAttemptContent.userInfo["fcm_options"] as? [String: Any],
                  let imageUrl = imageURLString["image"] as? String else {
                contentHandler(bestAttemptContent)
                return
            }
            
            guard let url = URL(string: imageUrl) else {
                contentHandler(bestAttemptContent)
                return
            }
            
            downloadImage(from: url) { (attachment) in
                if let attachment = attachment {
                    bestAttemptContent.attachments = [attachment]
                }
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (location, response, error) in
            guard let location = location else {
                completion(nil)
                return
            }
            
            let tmpDir = NSTemporaryDirectory()
            let tmpFile = "file://".appending(tmpDir).appending(url.lastPathComponent)
            let tmpUrl = URL(string: tmpFile)!
            
            try? FileManager.default.moveItem(at: location, to: tmpUrl)
            
            if let attachment = try? UNNotificationAttachment(identifier: "photo", url: tmpUrl, options: nil) {
                completion(attachment)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
}
