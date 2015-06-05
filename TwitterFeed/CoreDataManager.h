//
//  CoreDataManager.h
//  TwitterFeed
//
//  Created by Anvar Azizov on 04.06.15.
//  Copyright (c) 2015 Anvar Azizov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataManager : NSObject

+ (instancetype)sharedManager;

- (void)saveContext;
- (NSManagedObjectContext *)managedObjectContext;
- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName;
- (void)cleanDatabase;

@end
