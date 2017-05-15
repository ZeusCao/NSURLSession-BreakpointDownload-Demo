//
//  MediaModel.h
//  NSURLSession-BreakpointDownload-Demo
//
//  Created by Zeus on 2017/5/9.
//  Copyright © 2017年 Zeus. All rights reserved.
//



#import <Foundation/Foundation.h>

// 枚举
typedef enum {
    Downloading = 0,    //下载中
    DownloadSuspended,  //暂停下载
    DownloadFinished,   //完成下载
    DownloadFailed,     //下载失败
}DownloadState;


// 用于传输数据的回调
typedef void(^ProgressBlock) (NSInteger receicedLength, NSInteger totalLength, float progress);

// 用于外界下载状态的回调
typedef void(^stateBlock) (DownloadState state);



@interface MediaModel : NSObject

@property(nonatomic, strong)NSString *url;  //视频下载url

@property(nonatomic, strong)NSOutputStream *stream;  //流

@property(nonatomic, assign)NSInteger totalLength;  //服务器返回请求的总长度

@property(nonatomic, assign)NSInteger receivedLength;  //接收到的数据长度

@property(nonatomic, assign)float progress;  //进度


@property(nonatomic, copy)ProgressBlock proBlock;

@property(nonatomic, copy)stateBlock staBlock;

@property (nonatomic,assign)DownloadState staus;


@end
