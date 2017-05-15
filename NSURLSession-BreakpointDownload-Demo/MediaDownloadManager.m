//
//  MediaDownloadManager.m
//  NSURLSession-BreakpointDownload-Demo
//
//  Created by Zeus on 2017/5/9.
//  Copyright © 2017年 Zeus. All rights reserved.
//

#import "MediaDownloadManager.h"
#import "NSString+Hash.h"

// 缓存主目录
#define MainCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"MainCache"]

// 保存文件名
#define MediaFileName(url)  [NSString stringWithFormat:@"%@.mp4",url.md5String] //.md5String

// 文件名的路径
#define MediaFileFullpath(url) [MainCachesDirectory stringByAppendingPathComponent:MediaFileName(url)]

// 文件的已下载长度（获取）
#define DownloadLength(url) [[[NSFileManager defaultManager] attributesOfItemAtPath:MediaFileFullpath(url) error:nil][NSFileSize] integerValue]

// 存储文件总长度的plist文件路径
#define TotalLengthFullpath [MainCachesDirectory stringByAppendingPathComponent:@"totalLength.plist"]


@interface MediaDownloadManager ()<NSURLSessionDelegate>

// 以md5之后的url作为key值
@property (nonatomic, strong) NSMutableDictionary *tasksDic; // 对应的task字典

// 以随机生成的task的随机数作为key
@property (nonatomic, strong) NSMutableDictionary *modelsDic; // 对应的下载的mediaModel字典



@end


@implementation MediaDownloadManager




// 设置成一个单例是为了让我们的下载任务不会被提前释放掉
+ (instancetype)sharedInstance
{
    static MediaDownloadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MediaDownloadManager alloc]init];
    });
    return manager;
}

// 开启/暂停任务
- (void)downloadWithModel:(MediaModel *)model ProgressBlock:(ProgressBlock)pBlock StateBlock:(stateBlock)sBlock;
{
   
    // 为空
    if (!model.url) {
        return;
    }
    // 文件下载完成
    if ([self isFinished:model.url]) {
        sBlock(DownloadFinished);
        NSLog(@"该资源已下载完成");
        return;
    }
    // 该资源已经存在（不确定当前是否在下载）
    if ([self.tasksDic objectForKey:MediaFileName(model.url)]) {
        // 根据url取到对应的task
        NSURLSessionDataTask *task = [self.tasksDic valueForKey:MediaFileName(model.url)];
        if (task.state == NSURLSessionTaskStateRunning) // 正在运行
        {
            [self pause:model.url];
        }
        else
        {
            [self start:model.url];
        }
        return;
    }
    
    // 第三种情况，该资源（在本次界面初始化之后）没有下载过，或者不存在
    // 创建缓存的目录文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:MainCachesDirectory]) {
        [fileManager createDirectoryAtPath:MainCachesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        
    }
    NSLog(@"========== %@",MainCachesDirectory);
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    
    // 创建流
    // 利用NSOutputStream往Path中写入数据（append为YES的话，每次写入都是追加到文件尾部）
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:MediaFileFullpath(model.url) append:YES];
    
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:model.url]];
    
    //设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-",DownloadLength(model.url)];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    // 创建一个data任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    NSUInteger taskIdentifier = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));
    [task setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
    
    // 保存任务
    [self.tasksDic setValue:task forKey:MediaFileName(model.url)];
 
    MediaModel *mediaModel = [[MediaModel alloc]init];
    mediaModel.url = model.url;
    mediaModel.proBlock = pBlock;
    mediaModel.staBlock = sBlock;
    mediaModel.stream = stream;
    [self.modelsDic setValue:mediaModel forKey:@(task.taskIdentifier).stringValue];

    [self start:model.url];
    
    
}

// 查询某个资源下载的进度
- (CGFloat)progress:(NSString *)url
{
    if ([self getFileTotalLength:url] == 0) {
        return 0.0;
    }
    else
    {
        return 1.0 * DownloadLength(url) / [self getFileTotalLength:url];
    }
}

// 查询下载资源的状态(该方法在外界没有调用，考虑到没完成的任务和完成的要分开显示，自己做本地化存储)
- (DownloadState )getState:(NSString *)url
{
    if (DownloadLength(url) == 0) // 没有下载过
    {
        return DownloadSuspended;
    }
    else if (DownloadLength(url) == [self getFileTotalLength:url]) // 已完成
    {
        return DownloadFinished;
    }
    else // 已经下载过部分
    {
        return DownloadSuspended;
    }
}


// 获取某个下载资源的总大小
- (NSInteger)getFileTotalLength:(NSString *)url
{
    return [[NSDictionary dictionaryWithContentsOfFile:TotalLengthFullpath][MediaFileName(url)]  integerValue];
}

// 判断该资源是否下载完成
- (BOOL)isFinished:(NSString *)url
{
    // 文件资源的总大小不为0 且 文件的已下载长度等于总大小
    if ([self getFileTotalLength:url] != 0 && DownloadLength(url) == [self getFileTotalLength:url]) {
        return YES; //下载完成
    }
    else
    {
        return NO;
    }
}

// 删除某个下载资源
- (void)deleteResource:(NSString *)url
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:MediaFileFullpath(url)]) {
        // 删除沙盒路径
        [fileManager removeItemAtPath:MediaFileFullpath(url) error:nil];
        // 删除任务
        [self.tasksDic removeObjectForKey:MediaFileName(url)];
        NSURLSessionDataTask *task = [self.tasksDic valueForKey:MediaFileName(url)];
        [self.modelsDic removeObjectForKey:@(task.taskIdentifier).stringValue];
        // 删除资源总长度
        if ([fileManager fileExistsAtPath:TotalLengthFullpath]) {
            NSMutableDictionary *lengthDic = [NSMutableDictionary dictionaryWithContentsOfFile:TotalLengthFullpath];
            [lengthDic removeObjectForKey:MediaFileName(url)];
            [lengthDic writeToFile:TotalLengthFullpath atomically:YES];
        }
    }
}


// 清空所有下载资源
- (void)deleteAllResource:(NSString *)url;
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:MediaFileFullpath(url)])
    {
        // 删除沙盒中所有资源
        [fileManager removeItemAtPath:MediaFileFullpath(url) error:nil];
        // 删除任务
        [[self.tasksDic allValues] makeObjectsPerformSelector:@selector(cancel)];
        [self.tasksDic removeAllObjects];

        for (MediaModel *model in [self.modelsDic allValues]) {
            [model.stream close];
        }
        [self.modelsDic removeAllObjects];
        
        // 删除资源总长度
        if ([fileManager fileExistsAtPath:MediaFileFullpath(url)]) {
            [fileManager removeItemAtPath:MediaFileFullpath(url) error:nil];
        }
    }
}


#pragma mark --- 开始下载 ---
- (void)start:(NSString *)url
{
    NSURLSessionDataTask *task = [self.tasksDic valueForKey:MediaFileName(url)];
    [task resume];
    // 根据url获取下载的model的信息
    NSString *taskKey = @(task.taskIdentifier).stringValue;
    MediaModel *model = [self.modelsDic valueForKey:taskKey];
    NSLog(@"$$$$$$model$$$$$$$$%@",model);
    
    model.staBlock(Downloading);
}


#pragma mark --- 暂停下载 ---
- (void)pause:(NSString *)url
{
    // 根据url取到对应的task
    NSURLSessionDataTask *task = [self.tasksDic valueForKey:MediaFileName(url)];
    // 暂停
    [task suspend];
    // 根据url获取下载model的信息
    MediaModel *model = [self.modelsDic valueForKey:@(task.taskIdentifier).stringValue];
    model.staBlock(DownloadSuspended);
    
}

#pragma mark ------  NSURLSessionDataDelegate 代理 ------------------
// 1.接收到响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    MediaModel *model = [self.modelsDic valueForKey:@(dataTask.taskIdentifier).stringValue];
    
    // 打开流
    [model.stream open];
    /*
     （Content-Length字段返回的是服务器对每次客户端请求要下载文件的大小）
     比如首次客户端请求下载文件A，大小为1000byte，那么第一次服务器返回的Content-Length = 1000，
     客户端下载到500byte，突然中断，再次请求的range为 “bytes=500-”，那么此时服务器返回的Content-Length为500
     所以对于单个文件进行多次下载的情况（断点续传），计算文件的总大小，必须把服务器返回的content-length加上本地存储的已经下载的文件大小
     */
    model.totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + DownloadLength(model.url);
    
    // 储存总长度的plist文件
    NSMutableDictionary *lengthDic = [NSMutableDictionary dictionaryWithContentsOfFile:TotalLengthFullpath];
    if (lengthDic == nil) {
        lengthDic = [NSMutableDictionary dictionary];
    }
    lengthDic[MediaFileName(model.url)] = @(model.totalLength);
    [lengthDic writeToFile:TotalLengthFullpath atomically:YES];
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}


// 2.接收到服务器返回的数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    MediaModel *model = [self.modelsDic valueForKey:@(dataTask.taskIdentifier).stringValue];
    
    // 写入数据
    [model.stream write:data.bytes maxLength:data.length];
    
    model.receivedLength = DownloadLength(model.url);
    model.progress = 1.0 * model.receivedLength / model.totalLength;
    NSLog(@"===============%f",model.progress);
    model.proBlock(model.receivedLength, model.totalLength, model.progress);
}

// 3.请求完毕（成功|失败）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    MediaModel *model = [self.modelsDic valueForKey:@(task.taskIdentifier).stringValue];
    if (!model) {
        return;
    }
    
    if ([self isFinished:model.url]) {
        // 下载完成
            model.staBlock(DownloadFinished);
        
    }
    else if (error)
    {
        // 下载失败
            model.staBlock(DownloadFailed);
    }
    
    // 关闭流
    [model.stream close];
    model.stream = nil;
    
    // 清除任务
    [self.tasksDic removeObjectForKey:MediaFileName(model.url)];
    [self.modelsDic removeObjectForKey:@(task.taskIdentifier).stringValue];
}





#pragma mark --- 字典的懒加载 ---
- (NSMutableDictionary *)tasksDic
{
    if (!_tasksDic) {
        _tasksDic = [NSMutableDictionary dictionary];
    }
    return _tasksDic;
}

- (NSMutableDictionary *)modelsDic
{
    if (!_modelsDic) {
        _modelsDic = [NSMutableDictionary dictionary];
    }
    return _modelsDic;
}



@end





