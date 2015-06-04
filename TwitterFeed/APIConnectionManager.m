//
//  APIConnectionManager.m
//  TwitterFeed
//
//  Created by Anvar Azizov on 04.06.15.
//  Copyright (c) 2015 Anvar Azizov. All rights reserved.
//

#import "APIConnectionManager.h"

@interface APIConnectionManager ()

@property (nonatomic, strong) ACAccount * twitterAccount;

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

- (void)searchTwitterWithQuery:(NSString *)query parameters:(NSString *)parameters account:(ACAccount *)account completionHandler:(TwitterRequestHandler)completioHandler
{

    NSString * stringURL = [[NSString stringWithFormat:@"https://api.twitter.com/1.1/search/tweets.json?q=%@&%@", query, parameters] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL * searchURL = [NSURL URLWithString:stringURL];
    
    SLRequest * searchRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:searchURL parameters:nil];
    
    searchRequest.account = account;
    
    [searchRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         completioHandler(responseData, urlResponse, error);
     }];
}

- (void)fetchRecentTweetsForQuery:(NSString *)query completionHandler:(TwitterRequestHandler)completionHandler
{
    ACAccountStore * account = [[ACAccountStore alloc] init];
    ACAccountType * accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [account requestAccessToAccountsWithType:accountType
                                     options:nil completion:^(BOOL granted, NSError *error)
     {
         if (granted == YES)
         {
             NSArray * arrayOfAccounts = [account accountsWithAccountType:accountType];
             
             if ([arrayOfAccounts count] > 0)
             {
                 self.twitterAccount = [arrayOfAccounts lastObject];
                 NSString * parameters = @"result_type=recent";
                 
                 [self searchTwitterWithQuery:query
                                   parameters:parameters
                                      account:self.twitterAccount
                            completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
                  {
                      completionHandler(responseData, urlResponse, error);
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

- (void)loadNewTweetsForQuery:(NSString *)query withSinceID:(NSString *)sinceID completionHandler:(TwitterRequestHandler)completionHandler
{
    NSString * parameters = [NSString stringWithFormat:@"since_id=%@", sinceID];
    
    [self searchTwitterWithQuery:query
                      parameters:parameters
                         account:self.twitterAccount
               completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         completionHandler(responseData, urlResponse, error);
     }];
}

- (void)loadOlderTweetsForQuery:(NSString *)query withMaxID:(NSString *)maxID completionHandler:(TwitterRequestHandler)completionHandler
{
    NSString * parameters = [NSString stringWithFormat:@"max_id=%@", maxID];
    
    [self searchTwitterWithQuery:query
                      parameters:parameters
                         account:self.twitterAccount
               completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         completionHandler(responseData, urlResponse, error);
     }];
}

@end
