//
//  APIConnectionManager.h
//  TwitterFeed
//
//  Created by Anvar Azizov on 04.06.15.
//  Copyright (c) 2015 Anvar Azizov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface APIConnectionManager : NSObject

// Completion block for Twitter API request.
typedef void(^TwitterRequestHandler)(NSData *responseData, NSHTTPURLResponse * urlResponse, NSError *error);

+ (instancetype)sharedManager;
- (void)searchTwitterWithQuery:(NSString *)query parameters:(NSString *)parameters completionHandler:(TwitterRequestHandler)completioHandler;
- (void)fetchRecentTweetsForQuery:(NSString *)query completionHandler:(TwitterRequestHandler)completionHandler;
- (void)loadNewTweetsForQuery:(NSString *)query withSinceID:(NSString *)sinceID completionHandler:(TwitterRequestHandler)completionHandler;
- (void)loadOlderTweetsForQuery:(NSString *)query withMaxID:(NSString *)maxID completionHandler:(TwitterRequestHandler)completionHandler;

@end
