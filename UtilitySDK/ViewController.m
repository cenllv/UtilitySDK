//
//  ViewController.m
//  UtilitySDK
//
//  Created by chujian on 13-10-12.
//  Copyright (c) 2013年 chujian. All rights reserved.
//

#import "ViewController.h"
#import "RefreshView.h"
@interface ViewController ()<RefreshViewDelegate,UITableViewDataSource,UITableViewDelegate>
{
    UITableView *_table;
    RefreshView *header;
    RefreshView *footer;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _table = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen]applicationFrame].size.width, [[UIScreen mainScreen]applicationFrame].size.height) style:UITableViewStylePlain];
    _table.delegate = self;
    _table.dataSource = self;
    [self.view addSubview:_table];
    
//    header = [[RefreshView alloc]initWithScrollView:_table refreshType:RefreshViewTypeHeader];
//    header.delegate = self;
//    header.needAudio = YES;

    footer = [[RefreshView alloc]initWithScrollView:_table refreshType:RefreshViewTypeFooter];
    footer.delegate = self;
    footer.needAudio = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark 数据源-代理
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//   [header endRefreshing];
//    [footer endRefreshing];
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.imageView.image = [UIImage imageNamed:@"lufy.jpeg"];
    cell.textLabel.text = @"helo";
    cell.detailTextLabel.text = @"上面的是刷新时间";
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (void)refreshViewBeginRefreshing:(RefreshView *)refreshView
{
//    [header endRefreshing];
      NSLog(@"in delegate... ...");
      [NSTimer scheduledTimerWithTimeInterval:5 target:footer selector:@selector(endRefreshing) userInfo:nil repeats:NO];
//     [NSTimer scheduledTimerWithTimeInterval:5 target:header selector:@selector(endRefreshing) userInfo:nil repeats:NO];
}

@end
