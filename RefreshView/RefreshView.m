//
//  ViewController.h
//  UtilitySDK
//
//  Created by chujian on 13-10-12.
//  Copyright (c) 2013年 chujian. All rights reserved.
//
#import "RefreshView.h"

#define kViewHeight 65.0

#define kTimeKey @"kRefreshHeaderViewTime"

#define kPullToRefresh @"上/下拉可以刷新"
#define kReleaseToRefresh @"松开立即刷新"
#define kRefreshing @"正在刷新..."

#define kArrowImageName @"arrow.png"
#define kSoundNormal @"normal.wav"
#define kSoundPull @"pull.wav"
#define kSoundRefreshing @"refreshing.wav"
#define kSoundEndRefresh @"end_refreshing.wav"
#define kBundleName @"Refresh.bundle"
#define kSrcName(file) [kBundleName stringByAppendingPathComponent:file]
const  NSInteger refreshHeaderTag = 500;
const  NSInteger refreshFooterTag = 501;
void playSystemSound(SystemSoundID inSystemSoundID,bool canPlay)
{
    if (canPlay) {
        AudioServicesPlaySystemSound(inSystemSoundID);
    }
}


@interface  RefreshView()

@property (nonatomic, assign, getter = getValidY) CGFloat validY;
@property (nonatomic, strong) NSDate *lastUpdateTime;
@end

@implementation RefreshView

- (void)initial
{
    // 1.自己的属性
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    CGFloat color = 230/255.0;
    self.backgroundColor = [UIColor colorWithRed:color green:color blue:color alpha:1];
    
    // 2.时间标签
    [self addSubview:_lastUpdateTimeLabel = [self labelWithFontSize:12]];
    
    // 3.状态标签
    [self addSubview:_statusLabel = [self labelWithFontSize:13]];
    
    // 4.箭头图片
    UIImageView *arrowImage = [[UIImageView alloc] init];
    arrowImage.contentMode = UIViewContentModeScaleAspectFit;
    arrowImage.image = [UIImage imageNamed:kSrcName(kArrowImageName)];
    [self addSubview:_arrowImage = arrowImage];
    
    // 5.指示器
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.hidden = YES;
    [self addSubview:_activityView = activityView];
    
    // 6.默认类型
    _type = RefreshViewTypeHeader;
    
}
- (void)setNeedAudio:(BOOL)needAudio
{
    _needAudio = needAudio;
    if (needAudio) {
        _pullId = [self loadId:kSoundPull];
        _normalId = [self loadId:kSoundNormal];
        _refreshingId = [self loadId:kSoundRefreshing];
        _endRefreshId = [self loadId:kSoundEndRefresh];
    }
}
- (void)awakeFromNib
{
    [self initial];
}
- (id)initWithScrollView:(UIScrollView *)scrollView
{
    if (self = [super init]) {
        [self initial];
        self.scrollView = scrollView;
    }
    return self;
}
- (id)initWithScrollView:(UIScrollView *)scrollView refreshType:(RefreshViewType)type
{
    if (self = [self initWithScrollView:scrollView]) {
        _type = type;
        if (_type == RefreshViewTypeFooter) {
            
            [_scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            
            [_lastUpdateTimeLabel removeFromSuperview];
            _lastUpdateTimeLabel = nil;
            
            [self adjustFrameForRefreshViewTypeFooter];
            self.tag = refreshFooterTag;
        }else if(_type == RefreshViewTypeHeader){
            
            [self adjustFrameForRefreshViewTypeHeader];
            self.tag = refreshHeaderTag;
        }
        [self setState:RefreshStateNormal];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initial];
    }
    return self;
}

- (UILabel *)labelWithFontSize:(CGFloat)size
{
    UILabel *label = [[UILabel alloc] init];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.font = [UIFont boldSystemFontOfSize:size];
    CGFloat color = 178/255.0;
    label.textColor = [UIColor colorWithRed:color green:color blue:color alpha:1.0];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

- (SystemSoundID)loadId:(NSString *)filename
{
    SystemSoundID ID;
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url = [bundle URLForResource:kSrcName(filename) withExtension:nil];
    AudioServicesCreateSystemSoundID((__bridge  CFURLRef)(url), &ID);
    return ID;
}



- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    CGFloat statusY = 5;
    
    if (frame.size.width == 0 || _statusLabel.frame.origin.y == statusY) return;
    
    // 1.状态标签
    
    CGFloat statusX = 0;
    CGFloat statusHeight = 20;
    CGFloat statusWidth = self.frame.size.width;
    _statusLabel.frame = CGRectMake(statusX, statusY, statusWidth, statusHeight);
    
    // 2.时间标签
    CGFloat lastUpdateY = statusY + statusHeight + 5;
    _lastUpdateTimeLabel.frame = CGRectMake(statusX, lastUpdateY, statusWidth, statusHeight);
    
    // 3.箭头
    CGFloat arrowX = 20;
    _arrowImage.frame = CGRectMake(arrowX, statusY, 30.0f, 55.0f);
    
    // 4.指示器
    _activityView.bounds = CGRectMake(0, 0, 20.0f, 20.0f);
    _activityView.center = _arrowImage.center;
}
- (void)adjustFrameForRefreshViewTypeHeader
{
    self.frame = CGRectMake(0, -kViewHeight, _scrollView.frame.size.width, kViewHeight);
    
    _lastUpdateTime = [[NSUserDefaults standardUserDefaults] objectForKey:kTimeKey];
    
    [self updateTimeLabel];
}
- (void)adjustFrameForRefreshViewTypeFooter
{
    // 内容的高度
    CGFloat contentHeight = _scrollView.contentSize.height;
    // 表格的高度
    CGFloat scrollHeight = _scrollView.frame.size.height;
    CGFloat y = MAX(contentHeight, scrollHeight);
    // 设置边框
    self.frame = CGRectMake(0, y, _scrollView.frame.size.width, kViewHeight);
    
    // 挪动标签的位置
    CGPoint center = _statusLabel.center;
    center.y = _arrowImage.center.y;
    _statusLabel.center = center;
}
- (void)setScrollView:(UIScrollView *)scrollView
{
    // 移除之前的监听器
    [_scrollView removeObserver:self forKeyPath:@"contentOffset" context:nil];
    // 设置scrollView
    _scrollView = scrollView;
    [_scrollView addSubview:self];
    // 监听contentOffset
    [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)free
{
    [_scrollView removeObserver:self forKeyPath:@"contentOffset" context:nil];
    if (_type == RefreshViewTypeFooter) {
        [_scrollView removeObserver:self forKeyPath:@"contentSize" context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (_type == RefreshViewTypeFooter) {
        UIView *header = [_scrollView viewWithTag:refreshHeaderTag];
        if (header && [header isKindOfClass:[RefreshView class]] && ((RefreshView *)header).refreshing) {
            return;
        }
    }else if(_type == RefreshViewTypeHeader){
        UIView *footer = [_scrollView viewWithTag:refreshFooterTag];
        if (footer && [footer isKindOfClass:[RefreshView class]] && ((RefreshView *)footer).refreshing) {
            return;
        }
    }
    if ([@"contentOffset" isEqualToString:keyPath]) {
        CGFloat offsetY = _scrollView.contentOffset.y * _type;
        
        if (!self.userInteractionEnabled || self.alpha <= 0.01 || self.hidden
            || _state == RefreshStateRefreshing
            || offsetY <= self.validY) return;
        
        CGFloat validOffsetY = self.validY + kViewHeight;
        // 即将刷新 && 手松开
        if (_scrollView.isDragging) {
            
            if ( _state == RefreshStatePulling && offsetY <= validOffsetY) {
                // 转为普通状态
                playSystemSound(_normalId,_needAudio);

                [self setState:RefreshStateNormal];
            } else if ( _state == RefreshStateNormal && offsetY > validOffsetY ){
                // 转为即将刷新状态
                playSystemSound(_pullId,_needAudio);

                [self setState:RefreshStatePulling];
            }
        } else {
            if ( _state == RefreshStatePulling) {
                // 开始刷新

                playSystemSound(_refreshingId,_needAudio);

                [self setState:RefreshStateRefreshing];
            }
        }
    }
    
    if (_type == RefreshViewTypeFooter && [@"contentSize" isEqualToString:keyPath]) {
        [self adjustFrameForRefreshViewTypeFooter];
    }
}
- (void)setLastUpdateTime:(NSDate *)lastUpdateTime
{
    _lastUpdateTime = lastUpdateTime;
    
    // 归档
    [[NSUserDefaults standardUserDefaults] setObject:_lastUpdateTime forKey:kTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 更新时间
    [self updateTimeLabel];
}
- (void)updateTimeLabel
{
    if (!_lastUpdateTime) return;
    
    // 1.获得年月日
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit |NSHourCalendarUnit |NSMinuteCalendarUnit;
    NSDateComponents *cmp1 = [calendar components:unitFlags fromDate:_lastUpdateTime];
    NSDateComponents *cmp2 = [calendar components:unitFlags fromDate:[NSDate date]];
    
    // 2.格式化日期
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if ([cmp1 day] == [cmp2 day]) { // 今天
        formatter.dateFormat = @"今天 HH:mm";
    } else if ([cmp1 year] == [cmp2 year]) { // 今年
        formatter.dateFormat = @"MM-dd HH:mm";
    } else {
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    }
    NSString *time = [formatter stringFromDate:_lastUpdateTime];
    
    // 3.显示日期
    _lastUpdateTimeLabel.text = [NSString stringWithFormat:@"最后更新：%@", time];
}
- (void)setState:(RefreshState)state
{
    if (_state == state) return;
    
    RefreshState oldState = _state;
    
    switch (_state = state) {
		case RefreshStateNormal:
        {
            _arrowImage.hidden = NO;
			[_activityView stopAnimating];
             _statusLabel.text = kPullToRefresh;
            
            if (_type == RefreshViewTypeHeader) {
                if (oldState == RefreshStateRefreshing) {
                    // 保存刷新时间
                    self.lastUpdateTime = [NSDate date];

                    playSystemSound(_endRefreshId,_needAudio);

                }
                [UIView animateWithDuration:0.2 animations:^{
                    _arrowImage.transform = CGAffineTransformIdentity;
                    UIEdgeInsets inset = _scrollView.contentInset;
                    inset.top = 0;
                    _scrollView.contentInset = inset;
                }];
            }else if(_type == RefreshViewTypeFooter){
                
                [UIView animateWithDuration:0.2 animations:^{
                    _arrowImage.transform = CGAffineTransformMakeRotation(M_PI);
                    UIEdgeInsets inset = _scrollView.contentInset;
                    inset.bottom = 0;
                    _scrollView.contentInset = inset;
                }];
            }
        }

			break;
            
        case RefreshStatePulling:
        {
            _statusLabel.text = kReleaseToRefresh;
            if (_type == RefreshViewTypeHeader) {

                [UIView animateWithDuration:0.2 animations:^{
                    _arrowImage.transform = CGAffineTransformMakeRotation(M_PI);
                    UIEdgeInsets inset = _scrollView.contentInset;
                    inset.top = 0;
                    _scrollView.contentInset = inset;
                }];
            }else if(_type == RefreshViewTypeFooter){
                
                [UIView animateWithDuration:0.2 animations:^{
                    _arrowImage.transform = CGAffineTransformIdentity;
                    UIEdgeInsets inset = _scrollView.contentInset;
                    inset.bottom = 0;
                    _scrollView.contentInset = inset;
                }];
            }
        }

            break;
            
		case RefreshStateRefreshing:
        {
            [_activityView startAnimating];
			_arrowImage.hidden = YES;
            _arrowImage.transform = CGAffineTransformIdentity;
            _statusLabel.text = kRefreshing;
            if (_type == RefreshViewTypeHeader) {
                
                [UIView animateWithDuration:0.2 animations:^{
                    // 1.顶部多出65的滚动范围
                    UIEdgeInsets inset = _scrollView.contentInset;
                    inset.top = kViewHeight;
                    _scrollView.contentInset = inset;
                    // 2.设置滚动位置
                    _scrollView.contentOffset = CGPointMake(0, -kViewHeight);
                }];
            }else if(_type == RefreshViewTypeFooter){
                
                [UIView animateWithDuration:0.2 animations:^{
                    // 1.顶部多出65的滚动范围
                    UIEdgeInsets inset = _scrollView.contentInset;
                    inset.bottom = self.frame.origin.y - _scrollView.contentSize.height +kViewHeight;
                    _scrollView.contentInset = inset;
                    
                    // 2.设置滚动位置
                    _scrollView.contentOffset = CGPointMake(0, self.validY + kViewHeight);
                }];
            }
            
            // 通知代理
            if ([_delegate respondsToSelector:@selector(refreshViewBeginRefreshing:)]) {
                [_delegate refreshViewBeginRefreshing:self];
            }
            
            // 回调
            if (_beginRefreshingBlock) {
                _beginRefreshingBlock(self);
            }
        }
            break;	
	}

}
- (CGFloat)getValidY
{
    return (_type == RefreshViewTypeHeader) ? 0.0f : MAX(_scrollView.contentSize.height, _scrollView.frame.size.height) - _scrollView.frame.size.height;
}

- (BOOL)isRefreshing
{
    return RefreshStateRefreshing == _state;
}

- (void)beginRefreshing
{
    [self setState:RefreshStateRefreshing];
}

- (void)endRefreshing
{
    [self setState:RefreshStateNormal];
}
@end


