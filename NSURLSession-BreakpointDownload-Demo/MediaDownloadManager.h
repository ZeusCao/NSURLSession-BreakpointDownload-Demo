//
//  MediaDownloadManager.h
//  NSURLSession-BreakpointDownload-Demo
//
//  Created by Zeus on 2017/5/9.
//  Copyright © 2017年 Zeus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MediaModel.h"


@interface MediaDownloadManager : NSObject

// 设置成一个单例是为了让我们的下载任务不会被提前释放掉
+ (instancetype)sharedInstance;

// 开启/暂停任务
- (void)downloadWithModel:(MediaModel *)model ProgressBlock:(ProgressBlock)pBlock StateBlock:(stateBlock)sBlock;

// 查询某个资源下载的进度
- (CGFloat)progress:(NSString *)url;

// 查询下载资源的状态
- (DownloadState)getState:(NSString *)url;

// 获取某个下载资源的总大小
- (NSInteger)getFileTotalLength:(NSString *)url;

// 判断该资源是否下载完成
- (BOOL)isFinished:(NSString *)url;

// 删除某个下载资源
- (void)deleteResource:(NSString *)url;

// 清空所有下载资源
- (void)deleteAllResource:(NSString *)url;


@end

