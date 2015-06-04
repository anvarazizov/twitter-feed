//
//  ViewController.m
//  TwitterFeed
//
//  Created by Anvar Azizov on 02.06.15.
//  Copyright (c) 2015 Anvar Azizov. All rights reserved.
//

#import "ViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "TweetCell.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (nonatomic, strong) ACAccount * twitterAccount;
@property (nonatomic, strong) NSArray * dataSource;
@property (nonatomic, strong) UIRefreshControl * refreshControl;
@property (nonatomic, strong) UIView * footerView;
@property (nonatomic, strong) UIActivityIndicatorView * bottomLoader;

@end

#define kTableViewContentSection 0
#define kTableViewLoadMoreSection 1
#define CELL_BOTTOM_PADDING 10

// Completion block for Twitter API request.
typedef void(^TwitterRequestHandler)(NSData *responseData, NSHTTPURLResponse * urlResponse, NSError *error);

static NSString * kSearchQuery = @"india";

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UINib * nib = [UINib nibWithNibName:@"TweetCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"tweetCell"];
    
    [self fetchRecentTweets];
    
    self.title = @"Tweets";
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(loadNewTweets)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    [self initFooterView];
}

- (void)initFooterView
{
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 40.0)];
    
    self.bottomLoader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.bottomLoader.frame = CGRectMake(150.0, 5.0, 20.0, 20.0);
    self.bottomLoader.hidesWhenStopped = YES;
    
    [self.footerView addSubview:self.bottomLoader];
}

- (void)fetchRecentTweets
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
            
                 [self searchTwitterWithQuery:kSearchQuery
                                   parameters:parameters
                                      account:self.twitterAccount
                            completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
                 {
                     NSDictionary * result = [NSJSONSerialization
                                              JSONObjectWithData:responseData
                                              options:NSJSONReadingMutableLeaves
                                              error:&error];
                     
                     NSMutableArray * oldTweets = [[NSMutableArray alloc] initWithArray:self.dataSource];
                     NSMutableArray * newTweets = [[NSMutableArray alloc] initWithArray:[result objectForKey:@"statuses"]];
                     
                     [oldTweets addObjectsFromArray:newTweets];
                     
                     self.dataSource = [self removeDuplicatesFromArray:oldTweets];
                     
                     NSLog(@"%lu", (unsigned long)self.dataSource.count);
                     
                     if (self.dataSource.count != 0) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [self.tableView reloadData];
                         });
                     }
                 }];
             }
         }
         else
         {
             // Handle failure to get account access
         }
     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark – TableView Delegate and DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetCell * cell = (TweetCell *)[tableView dequeueReusableCellWithIdentifier:@"tweetCell" forIndexPath:indexPath];
        
    cell.authorLabel.text = [[[self.dataSource objectAtIndex:indexPath.row] objectForKey:@"user"] objectForKey:@"name"];
    cell.tweetLabel.text = [[self.dataSource objectAtIndex:indexPath.row] objectForKey:@"text"];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetCell * cell = (TweetCell *)[tableView dequeueReusableCellWithIdentifier:@"tweetCell"];
    
    NSString * authorText = [[[self.dataSource objectAtIndex:indexPath.row] objectForKey:@"user"] objectForKey:@"name"];
    NSString * tweetText = [[self.dataSource objectAtIndex:indexPath.row] objectForKey:@"text"];

    UIFont * font = [UIFont fontWithName:@"Helvetica Neue" size:14];
    
    CGRect authorRectSize = [authorText boundingRectWithSize:CGSizeMake(300.0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil];

    CGRect tweetRectSize = [tweetText boundingRectWithSize:CGSizeMake(300.0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil];
    
    CGSize rectSize = CGSizeMake(300, authorRectSize.size.height + tweetRectSize.size.height + cell.authorLabelToTop.constant + cell.tweetLbelToAuthorTop.constant + CELL_BOTTOM_PADDING);
    
    return rectSize.height;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate
{
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float height = size.height;
    
    float reloadDistance = 20;
    if(y > height + reloadDistance)
    {
        if (!aScrollView.dragging && !aScrollView.decelerating)
        {
            self.tableView.tableFooterView = self.footerView;
            [self.bottomLoader startAnimating];
            [self loadOlderTweets];
        }
    }
}

#pragma mark – API calls

- (void)loadNewTweets
{
    NSString * since_id = (NSString *)[[[self sortIDs] sortedArrayUsingSelector:@selector(compare:)] lastObject];
    
    NSString * parameters = [NSString stringWithFormat:@"since_id=%@", since_id];
    
    [self searchTwitterWithQuery:kSearchQuery
                      parameters:parameters
                         account:self.twitterAccount
               completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
    {
        NSDictionary * result = [NSJSONSerialization
                                 JSONObjectWithData:responseData
                                 options:NSJSONReadingMutableLeaves
                                 error:&error];
        
        NSMutableArray * oldTweets = [[NSMutableArray alloc] initWithArray:self.dataSource];
        NSMutableArray * newTweets = [[NSMutableArray alloc] initWithArray:[result objectForKey:@"statuses"]];
        
        [newTweets addObjectsFromArray:oldTweets];
        
        self.dataSource = [self removeDuplicatesFromArray:newTweets];
        
        NSLog(@"%lu", (unsigned long)self.dataSource.count);
        
        if (self.dataSource.count != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
    
                if (self.refreshControl)
                {
                    [self.refreshControl endRefreshing];
                }
            });
        }
    }];
}

- (void)loadOlderTweets
{
    NSString * maxID = (NSString *)[[[self sortIDs] sortedArrayUsingSelector:@selector(compare:)] firstObject];
    
    // fetch tweets with max_id
    NSString * parameters = [NSString stringWithFormat:@"max_id=%@", maxID];
    
    [self searchTwitterWithQuery:kSearchQuery
                      parameters:parameters
                         account:self.twitterAccount
               completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
    {
        NSDictionary * result = [NSJSONSerialization
                                 JSONObjectWithData:responseData
                                 options:NSJSONReadingMutableLeaves
                                 error:&error];
        
        NSMutableArray * oldTweets = [[NSMutableArray alloc] initWithArray:self.dataSource];
        NSMutableArray * newTweets = [[NSMutableArray alloc] initWithArray:[result objectForKey:@"statuses"]];
        
        [oldTweets addObjectsFromArray:newTweets];
        
        self.dataSource = [self removeDuplicatesFromArray:oldTweets];
        
        NSLog(@"%lu", (unsigned long)self.dataSource.count);
        
        if (self.dataSource.count != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                
                [self.bottomLoader stopAnimating];
            });
        }
    }];
}

- (void)searchTwitterWithQuery:(NSString *)query parameters:(NSString *)parameters account:(ACAccount *)account completionHandler:(TwitterRequestHandler)completioHandler
{
    NSURL * searchURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/search/tweets.json?q=%@&%@", query, parameters]];
    
    SLRequest * searchRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:searchURL parameters:nil];
    
    searchRequest.account = account;
    
    [searchRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
    {
        completioHandler(responseData, urlResponse, error);
    }];
}

- (NSArray *)removeDuplicatesFromArray:(NSArray *)array
{
    return [[NSOrderedSet orderedSetWithArray:array] array];
}

- (NSArray *)sortIDs
{
    NSMutableArray * newArray = [NSMutableArray new];
    
    for (NSDictionary * dict in self.dataSource)
    {
        [newArray addObject:[dict objectForKey:@"id"]];
    }
    
    return newArray;
}

@end
