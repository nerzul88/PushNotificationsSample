//
//  NotificationService.swift
//  NotificationsServiceExtension
//
//  Demo project for a Habr article about rich push notifications.
//

import Foundation
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {

    private enum PayloadKey {
        static let smallImageURL = "smallImageURL"
        static let bigImageURL = "bigImageURL"
    }

    private enum AttachmentIdentifier {
        static let smallImage = "small-image"
        static let bigImage = "big-image"
    }

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var didFinish = false

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }

        bestAttemptContent = content

        downloadImages(for: content) { [weak self] modifiedContent in
            self?.finish(with: modifiedContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        guard let bestAttemptContent else { return }
        finish(with: bestAttemptContent)
    }

    private func downloadImages(
        for content: UNMutableNotificationContent,
        completion: @escaping (UNMutableNotificationContent) -> Void
    ) {
        let group = DispatchGroup()
        let lock = NSLock()
        var downloadedAttachments: [String: UNNotificationAttachment] = [:]

        let images: [(key: String, identifier: String)] = [
            (PayloadKey.smallImageURL, AttachmentIdentifier.smallImage),
            (PayloadKey.bigImageURL, AttachmentIdentifier.bigImage)
        ]

        for image in images {
            guard
                let urlString = content.userInfo[image.key] as? String,
                let url = URL(string: urlString)
            else {
                continue
            }

            group.enter()
            downloadAttachment(from: url, identifier: image.identifier) { attachment in
                if let attachment {
                    lock.lock()
                    downloadedAttachments[image.identifier] = attachment
                    lock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Keep a deterministic order: the preview image comes first,
            // while the content extension explicitly selects the large image.
            content.attachments = [
                downloadedAttachments[AttachmentIdentifier.smallImage],
                downloadedAttachments[AttachmentIdentifier.bigImage]
            ].compactMap { $0 }

            completion(content)
        }
    }

    private func downloadAttachment(
        from url: URL,
        identifier: String,
        completion: @escaping (UNNotificationAttachment?) -> Void
    ) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 15

        let session = URLSession(configuration: configuration)
        let task = session.downloadTask(with: url) { temporaryURL, response, error in
            defer { session.finishTasksAndInvalidate() }

            guard
                error == nil,
                let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode),
                let temporaryURL
            else {
                completion(nil)
                return
            }

            do {
                let fileExtension = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
                let localURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(fileExtension)

                try FileManager.default.copyItem(at: temporaryURL, to: localURL)

                let attachment = try UNNotificationAttachment(
                    identifier: identifier,
                    url: localURL,
                    options: nil
                )

                completion(attachment)
            } catch {
                completion(nil)
            }
        }

        task.resume()
    }

    private func finish(with content: UNNotificationContent) {
        guard !didFinish else { return }
        didFinish = true
        contentHandler?(content)
        contentHandler = nil
    }
}
