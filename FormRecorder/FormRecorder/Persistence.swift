//
//  Persistence.swift
//  FormRecorder
//
//  Created by Param Grewal on 2026-02-24.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let workout = Workout(context: viewContext)
            workout.id = UUID()
            workout.date = Date()
            workout.exerciseType = "squat"
            workout.totalReps = 12
            workout.formScore = 0.87

            let set = WorkoutSet(context: viewContext)
            set.id = UUID()
            set.completedAt = Date()
            set.exerciseType = workout.exerciseType
            set.reps = 12
            set.targetReps = 12
            set.formScore = workout.formScore
            set.workout = workout
            workout.addToSets(set)
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FormRecorder")
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            fatalError("Missing persistent store description")
        }

        storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        if inMemory {
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
