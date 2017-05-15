//
//  ViewController.m
//  NSURLSession-BreakpointDownload-Demo
//
//  Created by Zeus on 2017/5/9.
//  Copyright © 2017年 Zeus. All rights reserved.
//

#import "ViewController.h"
#import "MediaModel.h"
#import "MediaCell.h"
#import "MediaDownloadManager.h"

@interface ViewController () <UITableViewDelegate,UITableViewDataSource>

@property(nonatomic, strong)NSMutableArray *modelArray;
@property(nonatomic, strong)UITableView *tableView;


@end

@implementation ViewController

- (NSMutableArray *)modelArray
{
    if (!_modelArray) {
        _modelArray = [NSMutableArray array];
    }
    return _modelArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self getAllData];
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 120;
    [self.tableView registerNib:[UINib nibWithNibName:@"MediaCell" bundle:nil] forCellReuseIdentifier:@"mediaCell"];
    [self.view addSubview:self.tableView];
    
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mediaCell"];
    MediaModel *model = self.modelArray[indexPath.row];
    
    // 进度条
    cell.progressView.progress = [[MediaDownloadManager sharedInstance]progress:model.url];
    // 进度
    cell.progressLabel.text = [NSString stringWithFormat:@"%.f%%",[[MediaDownloadManager sharedInstance]progress:model.url]*100];
    // 状态
    [cell.loadBtn setTitle:[self getTitleByState:model.staus] forState:UIControlStateNormal];
    cell.loadBtn.tag = indexPath.row + 1000;
    [cell.loadBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.deleteBtn.tag = 2000 + indexPath.row;
    [cell.deleteBtn addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}



#pragma mark --- 下载按钮点击事件 ---
- (void)clickAction:(UIButton *)button
{
    MediaModel *model = self.modelArray[button.tag - 1000];
    // 获取cell
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag - 1000 inSection:0];
    MediaCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    __weak ViewController *weakself = self;
    [[MediaDownloadManager sharedInstance]downloadWithModel:model ProgressBlock:^(NSInteger receicedLength, NSInteger totalLength, float progress) {
     
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.progressView.progress = progress;
            cell.progressLabel.text = [NSString stringWithFormat:@"%.f%%",progress*100];
//            NSArray *indexPathArray = @[indexPath];
//            [weakself.tableView reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
            [weakself.tableView reloadData];
        });
    } StateBlock:^(DownloadState state) {
        dispatch_async(dispatch_get_main_queue(), ^{
           // NSLog(@"===================%d",state);
            model.staus = state;
           [weakself.tableView reloadData];
        });
    }];
}

#pragma mark --- 删除按钮 ---
- (void)deleteAction:(UIButton *)button
{
    MediaModel *model = self.modelArray[button.tag - 2000];
    // 获取cell
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag - 2000 inSection:0];
    MediaCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    // 删除
    [[MediaDownloadManager sharedInstance]deleteResource:model.url];
    
    cell.progressView.progress = [[MediaDownloadManager sharedInstance]progress:model.url];
    // 进度
    cell.progressLabel.text = [NSString stringWithFormat:@"%.f%%",[[MediaDownloadManager sharedInstance]progress:model.url]*100];
    [cell.loadBtn setTitle:[self getTitleByState:DownloadSuspended] forState:UIControlStateNormal];
    [self.tableView reloadData];
}



#pragma mark --- 根据按钮状态切换按钮上的文字 ---
- (NSString *)getTitleByState:(DownloadState)state
{
    switch (state) {
        case Downloading:
            return @"暂停";
            break;
        case DownloadFailed:
        case DownloadSuspended:
            return @"开始";
        case DownloadFinished:
            return @"完成";
        default:
            break;
    }
}


// 获取数据源
- (void)getAllData
{
    MediaModel *model1 = [[MediaModel alloc]init];
    model1.url = @"http://120.25.226.186:32812/resources/videos/minion_01.mp4";
    model1.staus = DownloadSuspended;
    [self.modelArray addObject:model1];
    

    
    MediaModel *model4 = [[MediaModel alloc]init];
    model4.url =  @"http://imgcache.qq.com/qzone/biz/gdt/dev/sdk/ios/release/GDT_iOS_SDK.zip";
    model4.staus = DownloadSuspended;
    [self.modelArray addObject:model4];
    
    
    MediaModel *model5 = [[MediaModel alloc]init];
    model5.url = @"http://box.9ku.com/download.aspx?from=9ku";
    model5.staus = DownloadSuspended;
    [self.modelArray addObject:model5];
    
    
    MediaModel *model7 = [[MediaModel alloc]init];
    model7.url = @"http://cdn.macd.cn/data/attachment/forum/201504/20/141117h1inzffzi2cvfbi6.jpg";
    model7.staus = DownloadSuspended;
    [self.modelArray addObject:model7];

    MediaModel *model2 = [[MediaModel alloc]init];
    model2.url = @"http://android-mirror.bugly.qq.com:8080/eclipse_mirror/juno/content.jar";
    model2.staus = DownloadSuspended;
    [self.modelArray addObject:model2];
    
    
    MediaModel *model3 = [[MediaModel alloc]init];
    model3.url = @"http://dota2.dl.wanmei.com/dota2/client/DOTA2Setup20160329.zip";
    model3.staus = DownloadSuspended;
    [self.modelArray addObject:model3];
    
    MediaModel *model6 = [[MediaModel alloc]init];
    model6.url = @"http://pic6.nipic.com/20100330/4592428_113348097000_2.jpg";
    model6.staus = DownloadSuspended;
    [self.modelArray addObject:model6];
    
    
//    MediaModel *model8 = [[MediaModel alloc]init];
//    model8.url = @"http://cdn.macd.cn/data/attachment/forum/201504/20/141117h1inzffzi2cvfbi6.jpg";
//    model8.staus = DownloadSuspended;
//    [self.modelArray addObject:model8];
//    
//    MediaModel *model9 = [[MediaModel alloc]init];
//    model9.url = @"http://cdn.macd.cn/data/attachment/forum/201504/20/141117h1inzffzi2cvfbi6.jpg";
//    model9.staus = DownloadSuspended;
//    [self.modelArray addObject:model9];
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
