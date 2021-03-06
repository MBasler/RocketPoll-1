//
//  AppDelegate.swift
//  SocialPolling
//
//  Created by Igor Kantor on 12/19/14.
//  Copyright (c) 2014 Igor Kantor. All rights reserved.
//


//TODO

//On Ask click, collect responses and save to model
//- what is the best modeling pattern/library? mvvm support?





import UIKit
import CoreData
import Parse

@UIApplicationMain
class PollingAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var facebookUser: FBGraphUser?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        FBAppEvents.activateApp()

        ParseCrashReporting.enable();


//        SocialPolling (Beta)
//Parse.setApplicationId("HzV2hHIkPkjzIRyAfsVPozcB9ZemavFNurRqliYB", clientKey: "BoR07Tovxpg1hpJ6Q5ypmm6YESeObx4gStaWmdnf")

//        RocketPoll (Dev)
        Parse.setApplicationId("hh0OVgMMPgDaS2b6cmSY7RweUZDu09NtYF0LuOUS", clientKey: "cUzd7P3xSY54V2O6pA6oQ6RK0QOHGR2qEKHfSrDx")

        PFFacebookUtils.initializeFacebook()

        PFTwitterUtils .initializeWithConsumerKey("AKLOk4eRciUE8YtaNuxkFjR8G", consumerSecret: "YKBKBK9Cdpg4owXdKIcbB8XqIgQzrwOzVNRl49JiLyxarQqY9w")

        registerForPush(application)

        PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)



        return true
    }

    func registerForPush(application: UIApplication){
        var types: UIUserNotificationType =
            UIUserNotificationType.Badge |
            UIUserNotificationType.Alert |
            UIUserNotificationType.Sound

        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: types, categories: nil))
        application.registerForRemoteNotifications()
    }




    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData)
    {
        var installation = PFInstallation.currentInstallation()

        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackgroundWithBlock { (success, error) -> Void in
            if success {
                if PFUser.currentUser() != nil {
                    // if all went well, register for our own channel
                    var install = PFInstallation.currentInstallation()
                    install.setObject(["questions_to_\(PFUser.currentUser().objectId)", "answers_to_\(PFUser.currentUser().objectId)"], forKey: "channels")
                    install.saveInBackgroundWithBlock({ (success, error) -> Void in
                        if error != nil {
                            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                UIAlertView(title: "Error", message: error.description, delegate: nil, cancelButtonTitle: "OK").show()
                            })
                        }
                    })
                }
            }
            else
            {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    UIAlertView(title: "Error", message: error.description, delegate: nil, cancelButtonTitle: "OK").show()
                })
            }
        }
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
//        UIAlertView(title: "Error", message: error.description, delegate: nil, cancelButtonTitle: "OK").show()
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBAppCall.handleDidBecomeActiveWithSession(PFFacebookUtils.session())

        if(PFInstallation.currentInstallation().badge != 0){
            PFInstallation.currentInstallation().badge = 0
            PFInstallation.currentInstallation().saveEventually()
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return FBAppCall.handleOpenURL(url, sourceApplication:sourceApplication,
            withSession:PFFacebookUtils.session())
    }
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.igorware.CoreDataTest2" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
        }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("RocketPoll", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CoreDataTest2.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }

        return coordinator
        }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }

}

