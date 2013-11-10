//
//  PageView.h
//  UtilitySDK
//
//  Created by chujian on 13-11-5.
//  Copyright (c) 2013年 chujian. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    PageViewOrientationHorizontal = 0,
    PageViewOrientationVertical = 1
}PageViewOrientation;

@protocol PageViewDelegate;
@protocol PageViewDataSource;

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PageView : UIView<UIScrollViewDelegate,UITableViewDelegate>

@property (nonatomic, assign)   id <PageViewDataSource> dataSource;
@property (nonatomic, assign)   id <PageViewDelegate>   delegate;
@property (nonatomic, retain)   UIPageControl           *pageControl;
@property (nonatomic, assign)   CGFloat                 minimumPageAlpha;
@property (nonatomic, assign)   CGFloat                 minimumPageScale;
@property (nonatomic, assign)   PageViewOrientation     orientation;
@property (nonatomic, assign, readonly) NSInteger       currentPageIndex;


- (void)reloadData;
- (UIView *)dequeueReusablePage;
- (void)scrollToPage:(NSInteger)pageIndex;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol PageViewDataSource <NSObject>
- (NSInteger)numberOfPagesInPageView:(PageView *)pageView;
- (UIView *)pageView:(PageView *)pageView viewForPageAtIndex:(NSInteger)pageIndex;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol PageViewDelegate <NSObject>
- (CGSize)sizeForPageInPageView:(PageView *)PageView;
@optional
- (BOOL)pageViewShouldWrap:(PageView *)pageView;
- (void)pageView:(PageView *)pageView didScrollToPage:(NSInteger)pageIndex;
- (void)pageView:(PageView *)pageView didSelectPageAtIndex:(NSInteger)pageIndex;
- (BOOL)pageView:(PageView *)pageView shouldScrollToSelectedPage:(NSInteger)pageIndex;
@end
