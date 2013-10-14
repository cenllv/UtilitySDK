//
//  ViewController.h
//  UtilitySDK
//
//  Created by chujian on 13-10-12.
//  Copyright (c) 2013年 Mason All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
	RefreshStateNormal          = 1,
    RefreshStatePulling         = 2,
	RefreshStateRefreshing      = 3
} RefreshState;

typedef enum {
    RefreshViewTypeHeader       = -1,
    RefreshViewTypeFooter       = 1
} RefreshViewType;




@class RefreshView;

typedef void (^BeginRefreshingBlock)(RefreshView *refreshView);

@protocol RefreshViewDelegate <NSObject>
- (void)refreshViewBeginRefreshing:(RefreshView *)refreshView;
@end


#pragma mark - BaseRefreshView
@interface RefreshView : UIView
{
    // 父控件
    __weak UIScrollView *_scrollView;
    // 代理
    __weak id<RefreshViewDelegate> _delegate;
    // 回调
    BeginRefreshingBlock _beginRefreshingBlock;
    
    // 子控件
    __weak UILabel *_lastUpdateTimeLabel;
	__weak UILabel *_statusLabel;
    __weak UIImageView *_arrowImage;
	__weak UIActivityIndicatorView *_activityView;
    
    // 状态
    RefreshState _state;
    
    // 类型
    RefreshViewType _type;
    
    // 音效
    SystemSoundID _normalId;
    SystemSoundID _pullId;
    SystemSoundID _refreshingId;
    SystemSoundID _endRefreshId;

}

@property (nonatomic, weak, readonly)                   UILabel *lastUpdateTimeLabel;
@property (nonatomic, weak, readonly)                   UILabel *statusLabel;
@property (nonatomic, weak, readonly)                   UIImageView *arrowImage;
@property (nonatomic, readonly, getter=isRefreshing)    BOOL refreshing;

@property (nonatomic, copy)     BeginRefreshingBlock beginRefreshingBlock;
@property (nonatomic, weak)     id<RefreshViewDelegate> delegate;
@property (nonatomic, weak)     UIScrollView *scrollView;
@property (nonatomic)           BOOL needAudio;


- (id)initWithScrollView:(UIScrollView *)scrollView refreshType:(RefreshViewType)type;
- (void)beginRefreshing;
- (void)endRefreshing;
@end


