//
//  APIConnectionManager.m
//  TwitterFeed
//
//  Created by Anvar Azizov on 04.06.15.
//  Copyright (c) 2015 Anvar Azizov. All rights reserved.
//

#import "APIConnectionManager.h"

@interface APIConnectionManager ()

@end

@implementation APIConnectionManager

+ (instancetype)sharedManager
{
    static dispatch_once_t once;
    static APIConnectionManager * instance;
    
    dispatch_once(&once, ^{
        instance = [[APIConnectionManager alloc] init];
    });
    
    return instance;
}

// Basic method for Twitter search
- (void)searchTwitterWithQuery:(NSString *)query parameters:(NSString *)parameters completionHandler:(TwitterRequestHandler)completioHandler
{
    ACAccountStore * accountStore = [[ACAccountStore alloc] init];
    ACAccountType * accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType
                                     options:nil completion:^(BOOL granted, NSError *error)
     {
         if (granted == YES)
         {
             NSArray * arrayOfAccounts = [accountStore accountsWithAccountType:accountType];
             
             if ([arrayOfAccounts count] > 0)
             {
                ACAccount * twitterAccount = [arrayOfAccounts lastObject];
    
                NSString * stringURL = [[NSString stringWithFormat:@"https://api.twitter.com/1.1/search/tweets.json?q=%@&%@", query, parameters] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSURL * searchURL = [NSURL URLWithString:stringURL];
                
                SLRequest * searchRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:searchURL parameters:nil];
                
                searchRequest.account = twitterAccount;
                
                [searchRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
                 {
                     completioHandler(responseData, urlResponse, error);
                 }];
             }
             else
             {
                 UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Twitter Authorization"
                                                                  message:@"Please log into Twitter in the Settings and then try again!"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Ok"
                                                        otherButtonTitles: nil];
                 [alert show];
             }
         }
         else
         {
             UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Access restricted"
                                                              message:@"Please provide access to the Twitter account"
                                                             delegate:self
                                                    cancelButtonTitle:@"Ok"
                                                    otherButtonTitles: nil];
             [alert show];
         }
     }];
}

// fetches recent tweets
- (void)fetchRecentTweetsForQuery:(NSString *)query completionHandler:(TwitterRequestHandler)completionHandler
{
    NSString * parameters = @"result_type=recent";
                 
    [self searchTwitterWithQuery:query
                       parameters:parameters
                completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
    {
          completionHandler(responseData, urlResponse, error);
    }];
}

// fetches tweets newer than ones with since_id
- (void)loadNewTweetsForQuery:(NSString *)query withSinceID:(NSString *)sinceID completionHandler:(TwitterRequestHandler)completionHandler
{
    NSString * parameters = [NSString stringWithFormat:@"since_id=%@", sinceID];
    
    [self searchTwitterWithQuery:query
                      parameters:parameters
               completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         completionHandler(responseData, urlResponse, error);
     }];
}

// fetches tweets older than ones with max_id
- (void)loadOlderTweetsForQuery:(NSString *)query withMaxID:(NSString *)maxID completionHandler:(TwitterRequestHandler)completionHandler
{
    NSString * parameters = [NSString stringWithFormat:@"max_id=%@", maxID];
    
    [self searchTwitterWithQuery:query
                      parameters:parameters
               completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         completionHandler(responseData, urlResponse, error);
     }];
}

@end
