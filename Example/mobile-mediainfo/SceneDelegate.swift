/*  Copyright (c) MediaArea.net SARL. All Rights Reserved.
*
*  Use of this source code is governed by a BSD-style license that can
*  be found in the License.html file in the root of the source tree.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UISplitViewControllerDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard scene is UIWindowScene,
              let splitViewController = window?.rootViewController as? UISplitViewController,
              let navigationController = splitViewController.viewControllers.last as? UINavigationController,
              let reportsListNavigationController = splitViewController.viewControllers.first as? UINavigationController,
              let reportsListController = reportsListNavigationController.topViewController as? ReportsListViewController,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        reportsListController.managedObjectContext = appDelegate.persistentContainer.viewContext
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsReportController = secondaryAsNavController.topViewController as? ReportViewController else { return false }
        if topAsReportController.report == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
}
