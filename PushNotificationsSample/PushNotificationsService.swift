//
//  PushNotificationsService.swift
//  PushNotificationsSample
//
//  Demo project for a Habr article about rich push notifications.
//

import UIKit
import UserNotifications

final class PushNotificationsService {

    static let shared = PushNotificationsService()

    private enum Category {
        static let image = "pushWithImageCategory"
        static let event = "eventCategory"
    }

    private init() {}

    func configure() {
        registerNotificationCategories()
        requestAuthorization()
    }

    private func registerNotificationCategories() {
        let imageCategory = UNNotificationCategory(
            identifier: Category.image,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let eventCategory = UNNotificationCategory(
            identifier: Category.event,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            imageCategory,
            eventCategory
        ])
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, error in
            if let error {
                print("Notification permission error: \(error)")
                return
            }

            print("Notification permission granted: \(granted)")

            guard granted else { return }
            self?.registerForRemoteNotificationsIfAllowed()
        }
    }

    private func registerForRemoteNotificationsIfAllowed() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
