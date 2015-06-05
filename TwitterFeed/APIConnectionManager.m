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
                [self showAlertWithTitle:@"Twitter Authorization" andMessage:@"Please open Setting, log into Twitter and then try again!"];
            }
         }
         else
         {
            [self showAlertWithTitle:@"Access restricted" andMessage:@"Please provide access to the Twitter account"];
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

#pragma mark – Alert

- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:title
                                                                                  message:message
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction * okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) { /* place for action */ }];
        [alertController addAction:okAction];
        
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alertController animated:YES completion:nil];
    });
}

@end
