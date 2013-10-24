//
//  MScrollView.h
//  UtilitySDK
//
//  Created by chujian on 13-10-15.
//  Copyright (c) 2013年 chujian. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MScrollViewDelegate;
@protocol MScrollViewDatasource;

@interface MScrollView : UIView <UIScrollViewDelegate>

@property (nonatomic,readonly)    UIScrollView    *scrollView;
@property (nonatomic,readonly)    UIPageControl   *pageControl;

@property (nonatomic,strong)           NSMutableArray  *pagesArray;
@property (nonatomic,assign)           NSInteger   *currentPageIndex;
@property (nonatomic,assign)           BOOL    *autoScroll;
@property (nonatomic,assign) id<MScrollViewDelegate>delegate;
@property (nonatomic,assign) id<MScrollViewDatasource>datasource;
@end


@protocol MScrollViewDelegate <NSObject>

@optional
- (void)didClickPage:(MScrollView *)msView atIndex:(NSInteger)index;

@end

@protocol MScrollViewDatasource <NSObject>

@required
- (NSInteger)numberOfPages;
- (UIView *)pageAtIndex:(NSInteger)index;

@end