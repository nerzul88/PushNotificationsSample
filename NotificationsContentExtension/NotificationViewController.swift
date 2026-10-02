//
//  NotificationViewController.swift
//  NotificationsContentExtension
//
//  Demo project for a Habr article about rich push notifications.
//

import Foundation
import UIKit
import UserNotifications
import UserNotificationsUI

final class NotificationViewController: UIViewController, UNNotificationContentExtension {

    private enum Category {
        static let image = "pushWithImageCategory"
        static let event = "eventCategory"
    }

    private enum PayloadKey {
        static let eventDate = "eventDate"
        static let eventLocation = "eventLocation"
    }

    private enum AttachmentIdentifier {
        static let bigImage = "big-image"
    }

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let calendarImageView = NotificationViewController.makeSymbolImageView(
        systemName: "calendar"
    )

    private let locationImageView = NotificationViewController.makeSymbolImageView(
        systemName: "mappin.and.ellipse"
    )

    private let eventDateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        return label
    }()

    private let eventLocationLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        return label
    }()

    private lazy var dateRowStackView = makeEventRow(
        icon: calendarImageView,
        label: eventDateLabel
    )

    private lazy var locationRowStackView = makeEventRow(
        icon: locationImageView,
        label: eventLocationLabel
    )

    private lazy var eventStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            dateRowStackView,
            locationRowStackView
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.isHidden = true
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(imageView)
        view.addSubview(eventStackView)
        setupConstraints()
    }

    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content

        switch content.categoryIdentifier {
        case Category.image:
            configureImageNotification(with: content)

        case Category.event:
            configureEventNotification(with: content)

        default:
            break
        }
    }

    private func configureImageNotification(with content: UNNotificationContent) {
        eventStackView.isHidden = true
        imageView.isHidden = false

        guard let imageAttachment = content.attachments.first(where: {
            $0.identifier == AttachmentIdentifier.bigImage
        }) else {
            return
        }

        loadImage(from: imageAttachment)
    }

    private func configureEventNotification(with content: UNNotificationContent) {
        imageView.isHidden = true
        eventStackView.isHidden = false

        let eventDate = content.userInfo[PayloadKey.eventDate] as? String
        let eventLocation = content.userInfo[PayloadKey.eventLocation] as? String

        eventDateLabel.text = eventDate ?? "Date not specified"
        eventLocationLabel.text = eventLocation ?? "Location not specified"

        preferredContentSize = CGSize(
            width: view.bounds.width,
            height: 112
        )
    }

    private func loadImage(from attachment: UNNotificationAttachment) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let didStartAccessing = attachment.url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    attachment.url.stopAccessingSecurityScopedResource()
                }
            }

            guard
                let data = try? Data(contentsOf: attachment.url),
                let image = UIImage(data: data)
            else {
                return
            }

            DispatchQueue.main.async {
                guard let self else { return }
                self.preferredContentSize = self.preferredImageSize(for: image.size)
                self.imageView.image = image
            }
        }
    }

    private func preferredImageSize(for imageSize: CGSize) -> CGSize {
        let availableWidth = view.bounds.width

        guard availableWidth > 0, imageSize.width > availableWidth else {
            return imageSize
        }

        let scale = availableWidth / imageSize.width
        return CGSize(
            width: availableWidth,
            height: imageSize.height * scale
        )
    }

    private func makeEventRow(
        icon: UIImageView,
        label: UILabel
    ) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [icon, label])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 10

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])

        return stackView
    }

    private static func makeSymbolImageView(
        systemName: String
    ) -> UIImageView {
        let imageView = UIImageView(
            image: UIImage(systemName: systemName)
        )
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        return imageView
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            eventStackView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            eventStackView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            eventStackView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
            eventStackView.bottomAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            )
        ])
    }
}
