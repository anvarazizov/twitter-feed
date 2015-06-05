//
//  ViewController.m
//  TwitterFeed
//
//  Created by Anvar Azizov on 02.06.15.
//  Copyright (c) 2015 Anvar Azizov. All rights reserved.
//

#import "ViewController.h"
#import "TweetCell.h"
#import "APIConnectionManager.h"
#import "CoreDataManager.h"
#import "Tweet.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (nonatomic, strong) NSArray * dataSource;
@property (nonatomic, strong) UIRefreshControl * refreshControl;
@property (nonatomic, strong) UIView * footerView;
@property (nonatomic, strong) UIActivityIndicatorView * bottomLoader;

@end

static NSString * kSearchQuery = @"#india";
static NSString * kFileName = @"tweets";

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Tweets";
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TweetCell" bundle:nil] forCellReuseIdentifier:@"tweetCell"];
   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initRefreshControl];
    [self initFooterView];
    [self populateTableView];
}

- (void)populateTableView
{
    if ([self isNetworkReachable])
    {
        [[CoreDataManager sharedManager] cleanDatabase];
        [self fetchRecentTweets];
    } else {
        [self loadTweetsFromDatabase];
    }
}

- (void)initRefreshControl
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(loadNewTweets)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)initFooterView
{
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 40.0)];
    
    self.bottomLoader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.bottomLoader.frame = CGRectMake(0, 0, 20.0, 20.0);
    self.bottomLoader.center = CGPointMake(self.view.center.x, self.footerView.center.y);
    self.bottomLoader.hidesWhenStopped = YES;
    
    [self.footerView addSubview:self.bottomLoader];
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
        
    cell.authorLabel.text = [[[self.dataSource objectAtIndex:indexPath.row] objectForKey:@"user"] objectForKey:@"screen_name"];
    cell.tweetLabel.text = [[self.dataSource objectAtIndex:indexPath.row] objectForKey:@"text"];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetCell * cell = (TweetCell *)[tableView dequeueReusableCellWithIdentifier:@"tweetCell"];
    
    NSString * authorText = [[[self.dataSource objectAtIndex:indexPath.row] objectForKey:@"user"] objectForKey:@"screen_name"];
    NSString * tweetText = [[self.dataSource objectAtIndex:indexPath.row] objectForKey:@"text"];

    UIFont * font = [UIFont fontWithName:@"Helvetica Neue" size:14];
    
    CGRect authorRectSize = [authorText boundingRectWithSize:CGSizeMake(300.0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil];

    CGRect tweetRectSize = [tweetText boundingRectWithSize:CGSizeMake(300.0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil];
    
    CGSize rectSize = CGSizeMake(300, authorRectSize.size.height + tweetRectSize.size.height + cell.authorLabelToTop.constant + cell.tweetLbelToAuthorTop.constant + self.view.bounds.size.height / 30);
    
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

- (void)fetchRecentTweets
{
    [[APIConnectionManager sharedManager] fetchRecentTweetsForQuery:kSearchQuery completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
    {
        if (responseData)
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
        }
    }];
}

- (void)loadNewTweets
{
    NSArray * ids = [self sortIDs];
    NSNumber * sinceID = [[ids sortedArrayUsingSelector:@selector(compare:)] lastObject];
    
    [[APIConnectionManager sharedManager] loadNewTweetsForQuery:kSearchQuery withSinceID:[sinceID stringValue] completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
    {
        if (responseData)
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
        }
        else
        {
            [self.refreshControl endRefreshing];
        }
    }];
}

- (void)loadOlderTweets
{
    NSArray * ids = [self sortIDs];
    NSNumber * maxID = [[ids sortedArrayUsingSelector:@selector(compare:)] firstObject];
    
    [[APIConnectionManager sharedManager] loadOlderTweetsForQuery:kSearchQuery withMaxID:[maxID stringValue] completionHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
    {
        if (responseData)
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
        }
    }];
}

#pragma mark – Helpers

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

- (BOOL)isNetworkReachable
{
    // checking data from very small webpage
    NSURL * url = [NSURL URLWithString:@"http://anvarazizov.com/reachability/"];
    NSData * data = [NSData dataWithContentsOfURL:url];
    
    if (data)
        return YES;
    else
        return NO;
}

- (NSString *)filePathForArchive
{
    NSString * documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString * filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectoryPath, kFileName];
    
    return filePath;
}

#pragma mark – Data caching

- (void)saveTweets
{
    for (NSDictionary * dict in self.dataSource)
    {
        Tweet * tweet = [NSEntityDescription insertNewObjectForEntityForName:@"Tweet" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
        tweet.author = [[dict objectForKey:@"user"] objectForKey:@"screen_name"];
        tweet.text = [dict objectForKey:@"text"];
        tweet.twitID = [NSNumber numberWithInteger:[[dict objectForKey:@"id"] integerValue]];
    }
    
    [[CoreDataManager sharedManager] saveContext];
}

- (void)loadTweetsFromDatabase
{
    NSMutableArray * loadedTweets = [NSMutableArray new];
    NSArray * loadedObjects = [[CoreDataManager sharedManager] fetchObjectsForEntityName:@"Tweet"];
    
    for (Tweet * tweet in loadedObjects)
    {
        NSMutableDictionary * dict = [NSMutableDictionary new];
        NSMutableDictionary * userDict = [NSMutableDictionary new];
        
        [dict setValue:tweet.twitID forKey:@"id"];
        [userDict setValue:tweet.author forKey:@"screen_name"];
        [dict setValue:userDict forKey:@"user"];
        [dict setValue:tweet.text forKey:@"text"];
        [loadedTweets addObject:dict];
    }
    
    self.dataSource = loadedTweets;
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self saveTweets];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self saveTweets];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    
}

@end