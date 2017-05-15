//
//  MediaCell.h
//  NSURLSession-BreakpointDownload-Demo
//
//  Created by Zeus on 2017/5/10.
//  Copyright © 2017年 Zeus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MediaCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@property (weak, nonatomic) IBOutlet UIButton *loadBtn;


@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;


@end
