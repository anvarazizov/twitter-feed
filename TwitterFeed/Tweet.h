//
//  Tweet.h
//  TwitterFeed
//
//  Created by Anvar Azizov on 04.06.15.
//  Copyright (c) 2015 Anvar Azizov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Tweet : NSManagedObject

@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * twitID;

@end
