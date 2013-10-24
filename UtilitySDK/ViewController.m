//
//  ViewController.m
//  UtilitySDK
//
//  Created by chujian on 13-10-12.
//  Copyright (c) 2013年 chujian. All rights reserved.
//

#import "ViewController.h"
#import "RefreshView.h"
#import "EScrollerView.h"
#import "PageScrollView.h"

@interface ViewController ()
{
    PageScrollView *page;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    _table = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen]applicationFrame].size.width, [[UIScreen mainScreen]applicationFrame].size.height) style:UITableViewStylePlain];
//    _table.delegate = self;
//    _table.dataSource = self;
//    [self.view addSubview:_table];
//    
////    header = [[RefreshView alloc]initWithScrollView:_table refreshType:RefreshViewTypeHeader];
////    header.delegate = self;
////    header.needAudio = YES;
//
//    footer = [[RefreshView alloc]initWithScrollView:_table refreshType:RefreshViewTypeFooter];
//    footer.delegate = self;
//    footer.needAudio = YES;
    
//    EScrollerView *sc = [[EScrollerView alloc]initWithFrameRect:CGRectMake(0, 0, 320, 100) ImageArray:[[NSArray alloc]initWithObjects:@"1.jpg",@"2.jpg",@"3.jpg", nil] TitleArray:@[@"11",@"22",@"33"]];
//    [self.view addSubview:sc];
    
    
//    page = [[PageScrollView alloc]initWithFrame:CGRectMake(0, 100, 320, 100) pages:nil];
//    [self.view addSubview:page];
    MMScrollView *v = [[MMScrollView alloc]initWithFrame:self.view.bounds];
    AView *a = [[AView alloc]initWithFrame:self.view.bounds];
    BView *b = [[BView alloc]initWithFrame:self.view.bounds];
//    [a addSubview:b];
    [self.view addSubview:v];
    [self.view addSubview:b];
    [self.view addSubview:a];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//#pragma mark 数据源-代理
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
////   [header endRefreshing];
////    [footer endRefreshing];
//    return 2;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
//    }
//    
//    cell.imageView.image = [UIImage imageNamed:@"lufy.jpeg"];
//    cell.textLabel.text = @"helo";
//    cell.detailTextLabel.text = @"上面的是刷新时间";
//    
//    return cell;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 100;
//}
//
//- (void)refreshViewBeginRefreshing:(RefreshView *)refreshView
//{
////    [header endRefreshing];
//      NSLog(@"in delegate... ...");
//      [NSTimer scheduledTimerWithTimeInterval:5 target:footer selector:@selector(endRefreshing) userInfo:nil repeats:NO];
////     [NSTimer scheduledTimerWithTimeInterval:5 target:header selector:@selector(endRefreshing) userInfo:nil repeats:NO];
//}

@end
