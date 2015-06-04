//
//  TweetCell.h
//  TwitterFeed
//
//  Created by Anvar Azizov on 04.06.15.
//  Copyright (c) 2015 Anvar Azizov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TweetCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel * authorLabel;
@property (weak, nonatomic) IBOutlet UILabel * tweetLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint * authorLabelToTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * tweetLbelToAuthorTop;


@end
