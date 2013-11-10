//
//  PageView.m
//  UtilitySDK
//
//  Created by chujian on 13-11-5.
//  Copyright (c) 2013年 chujian. All rights reserved.
//

#import "PageView.h"

@interface ExternalScrollView : UIScrollView
@end

@interface TapGestureRecognizer : UITapGestureRecognizer
@property (nonatomic,assign) NSInteger tapId;
@property (nonatomic,assign) NSInteger gestureId;
@end

@interface PageView()
{
    PageViewOrientation _orientation;//默认为横向
    
    ExternalScrollView        *_scrollView;
    BOOL                _needsReload;
    CGSize              _pageSize; //一页的尺寸
    NSInteger           _dataSourcePageCount;  //数据源数目
    NSInteger           _appendingPageCount;    //附加数目
    NSInteger           _currentPageIndex;
    
    NSMutableArray      *_pages;
    NSRange              _visibleRange;
    NSMutableArray      *_reusablePages;//如果以后需要支持reuseIdentifier，这边就得使用字典类型了
    BOOL                _shouldResetOffset;
}
@property (nonatomic, assign, readwrite) NSInteger currentPageIndex;
@property (nonatomic, assign) BOOL shouldWrap;
@end

@implementation PageView
@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;
@synthesize pageControl = _pageControl;
@synthesize minimumPageAlpha = _minimumPageAlpha,minimumPageScale = _minimumPageScale,orientation = _orientation,currentPageIndex =_currentPageIndex,shouldWrap = _shouldWrap;
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

- (void)initialize{
    
    self.clipsToBounds = YES;
    
    _needsReload = YES;
    _shouldResetOffset = YES;
    _shouldWrap = NO;
    _pageSize = self.bounds.size;
    _dataSourcePageCount = 0;
    _currentPageIndex = 0;
    
    _minimumPageAlpha = 1.0;
    _minimumPageScale = 1.0;
    
    _visibleRange = NSMakeRange(0, 0);
    
    _reusablePages = [[NSMutableArray alloc] initWithCapacity:0];
    _pages = [[NSMutableArray alloc] initWithCapacity:0];
    
    _scrollView = [[ExternalScrollView alloc] initWithFrame:self.bounds];
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.clipsToBounds = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    
    /*由于UIScrollView在滚动之后会调用自己的layoutSubviews以及父View的layoutSubviews
     这里为了避免scrollview滚动带来自己layoutSubviews的调用,所以给scrollView加了一层父View
     */
    UIView *superViewOfScrollView = [[UIView alloc] initWithFrame:self.bounds];
    [superViewOfScrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [superViewOfScrollView setBackgroundColor:[UIColor clearColor]];
    [superViewOfScrollView addSubview:_scrollView];
    [self addSubview:superViewOfScrollView];
    
}

- (void)queueReusablePage:(UIView *)page{
    [_reusablePages addObject:page];
}

- (void)removePageAtIndex:(NSInteger)pageIndex{
    UIView *page = [_pages objectAtIndex:pageIndex];
    if ((NSObject *)page == [NSNull null]) {
        return;
    }
    
    [self queueReusablePage:page];
    
    if (page.superview) {
        [page removeFromSuperview];
    }
    
    [_pages replaceObjectAtIndex:pageIndex withObject:[NSNull null]];
}


- (void)setPageAtIndex:(NSInteger)pageIndex{
    
    NSParameterAssert(pageIndex >= 0 && pageIndex < [_pages count]);
    
    NSInteger index ;
    if (_shouldWrap) {
        if (pageIndex < _appendingPageCount/2) {
            index = _pages.count  - _appendingPageCount - _appendingPageCount/2 + pageIndex ;
        }else if(pageIndex < _pages.count  - _appendingPageCount/2){
            index = pageIndex - _appendingPageCount/2;
        }else{
            index = pageIndex - (_pages.count  - _appendingPageCount/2);
        }
    }
    
    UIView *page = [_pages objectAtIndex:pageIndex];
    
    if ((NSObject *)page == [NSNull null]) {
        page = [_dataSource pageView:self viewForPageAtIndex:(_shouldWrap ? index : pageIndex)];
        if (page.gestureRecognizers &&
            page.gestureRecognizers.count &&
            [page.gestureRecognizers[0] isKindOfClass:[TapGestureRecognizer class]]) {
            TapGestureRecognizer *tap = page.gestureRecognizers[0];
            tap.tapId = (_shouldWrap ? index : pageIndex);
            tap.gestureId = pageIndex;
        }else{
            TapGestureRecognizer *tap = [[TapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapPage:)];
            tap.tapId = (_shouldWrap ? index : pageIndex);
            tap.gestureId = pageIndex;
            [page addGestureRecognizer:tap];
        }
        
        NSAssert(page!=nil, @"datasource must not return nil");
        [_pages replaceObjectAtIndex:pageIndex withObject:page];
        
        switch (_orientation) {
            case PageViewOrientationHorizontal:
                page.frame = CGRectMake(_pageSize.width * pageIndex, 0, _pageSize.width, _pageSize.height);
                break;
            case PageViewOrientationVertical:
                page.frame = CGRectMake(0, _pageSize.height * pageIndex, _pageSize.width, _pageSize.height);
                break;
            default:
                break;
        }
        
        if (!page.superview) {
            [_scrollView addSubview:page];
        }
    }
}


- (void)setPagesAtContentOffset:(CGPoint)offset{
    //计算_visibleRange
    CGPoint startPoint = CGPointMake(offset.x - _scrollView.frame.origin.x, offset.y - _scrollView.frame.origin.y);
    CGPoint endPoint = CGPointMake(startPoint.x + self.bounds.size.width, startPoint.y + self.bounds.size.height);
    
    switch (_orientation) {
        case PageViewOrientationHorizontal:{
            NSInteger startIndex = 0;
            for (int i =0; i < [_pages count]; i++) {
                if (_pageSize.width * (i +1) > startPoint.x) {
                    startIndex = i;
                    break;
                }
            }
            
            NSInteger endIndex = startIndex;
            for (int i = startIndex; i < [_pages count]; i++) {
                //如果都不超过则取最后一个
                if ((_pageSize.width * (i + 1) < endPoint.x && _pageSize.width * (i + 2) >= endPoint.x) || i+ 2 == [_pages count]) {
                    endIndex = i + 1;//i+2 是以个数，所以其index需要减去1
                    break;
                }
            }
            
            //可见页分别向前向后扩展一个，提高效率
            startIndex = MAX(startIndex - 1, 0);
            endIndex = MIN(endIndex + 1, [_pages count] - 1);
            _visibleRange.location = startIndex;
            _visibleRange.length = endIndex - startIndex + 1;
            
            for (int i = startIndex; i <= endIndex; i++) {
                [self setPageAtIndex:i];
            }
            
            for (int i = 0; i < startIndex; i ++) {
                [self removePageAtIndex:i];
            }
            
            for (int i = endIndex + 1; i < [_pages count]; i ++) {
                [self removePageAtIndex:i];
            }
            break;
        }
        case PageViewOrientationVertical:{
            NSInteger startIndex = 0;
            for (int i =0; i < [_pages count]; i++) {
                if (_pageSize.height * (i +1) > startPoint.y) {
                    startIndex = i;
                    break;
                }
            }
            
            NSInteger endIndex = startIndex;
            for (int i = startIndex; i < [_pages count]; i++) {
                //如果都不超过则取最后一个
                if ((_pageSize.height * (i + 1) < endPoint.y && _pageSize.height * (i + 2) >= endPoint.y) || i+ 2 == [_pages count]) {
                    endIndex = i + 1;//i+2 是以个数，所以其index需要减去1
                    break;
                }
            }
            
            //可见页分别向前向后扩展一个，提高效率
            startIndex = MAX(startIndex - 1, 0);
            endIndex = MIN(endIndex + 1, [_pages count] - 1);
            
            _visibleRange.location = startIndex;
            _visibleRange.length = endIndex - startIndex + 1;
            
            for (int i = startIndex; i <= endIndex; i++) {
                [self setPageAtIndex:i];
            }
            
            for (int i = 0; i < startIndex; i ++) {
                [self removePageAtIndex:i];
            }
            
            for (int i = endIndex + 1; i < [_pages count]; i ++) {
                [self removePageAtIndex:i];
            }
            break;
        }
        default:
            break;
    }
}

- (void)refreshVisiblePagesAppearance{
    
    if (_minimumPageAlpha == 1.0 && _minimumPageScale == 1.0) {
        return;//无需更新
    }
    switch (_orientation) {
        case PageViewOrientationHorizontal:{
            CGFloat offset = _scrollView.contentOffset.x;
            
            for (int i = _visibleRange.location; i < _visibleRange.location + _visibleRange.length; i++) {
                UIView *page = [_pages objectAtIndex:i];
                CGFloat origin = page.frame.origin.x;
                CGFloat delta = fabs(origin - offset);
                
                CGRect originPageFrame = CGRectMake(_pageSize.width * i, 0, _pageSize.width, _pageSize.height);//如果没有缩小效果的情况下的本该的Frame
                
                [UIView beginAnimations:@"pageAnimation" context:nil];
                if (delta < _pageSize.width) {
                    page.alpha = 1 - (delta / _pageSize.width) * (1 - _minimumPageAlpha);
                    
                    CGFloat inset = (_pageSize.width * (1 - _minimumPageScale)) * (delta / _pageSize.width)/2.0;
                    page.frame = UIEdgeInsetsInsetRect(originPageFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                } else {
                    page.alpha = _minimumPageAlpha;
                    CGFloat inset = _pageSize.width * (1 - _minimumPageScale) / 2.0 ;
                    page.frame = UIEdgeInsetsInsetRect(originPageFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                }
                [UIView commitAnimations];
            }
            break;
        }
        case PageViewOrientationVertical:{
            CGFloat offset = _scrollView.contentOffset.y;
            
            for (int i = _visibleRange.location; i < _visibleRange.location + _visibleRange.length; i++) {
                UIView *page = [_pages objectAtIndex:i];
                CGFloat origin = page.frame.origin.y;
                CGFloat delta = fabs(origin - offset);
                
                CGRect originPageFrame = CGRectMake(0, _pageSize.height * i, _pageSize.width, _pageSize.height);//如果没有缩小效果的情况下的本该的Frame
                
                [UIView beginAnimations:@"pageAnimation" context:nil];
                if (delta < _pageSize.height) {
                    page.alpha = 1 - (delta / _pageSize.height) * (1 - _minimumPageAlpha);
                    
                    CGFloat inset = (_pageSize.height * (1 - _minimumPageScale)) * (delta / _pageSize.height)/2.0;
                    page.frame = UIEdgeInsetsInsetRect(originPageFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                } else {
                    page.alpha = _minimumPageAlpha;
                    CGFloat inset = _pageSize.height * (1 - _minimumPageScale) / 2.0 ;
                    page.frame = UIEdgeInsetsInsetRect(originPageFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                }
                [UIView commitAnimations];
            }
        }
        default:
            break;
    }
}

- (void)calculateCurrentPageIndex:(UIScrollView *)scrollView
{
    NSInteger pageIndex;
    
    switch (_orientation) {
        case PageViewOrientationHorizontal:
            pageIndex = floor(_scrollView.contentOffset.x / _pageSize.width);
            break;
        case PageViewOrientationVertical:
            pageIndex = floor(_scrollView.contentOffset.y / _pageSize.height);
            break;
        default:
            break;
    }
    
    _currentPageIndex = pageIndex;
}
- (void)scrollToSelectedPage:(NSInteger)pageIndex
{
    if (pageIndex < _pages.count){
        [self calculateCurrentPageIndex:_scrollView];
        if (_shouldWrap) {
            switch (_orientation) {
                case PageViewOrientationHorizontal:
                {
                    NSInteger index ;
                    if (pageIndex < _appendingPageCount/2) {
                        index = (_pages.count - _appendingPageCount) + pageIndex ;
                        _shouldResetOffset = NO;
                        [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x + (_pages.count - _appendingPageCount) * _pageSize.width, 0) animated:NO];
                        _shouldResetOffset = YES;
                    }else if(pageIndex < _pages.count  - _appendingPageCount/2){
                        index = pageIndex ;
                    }else{
                        index = pageIndex - (_pages.count  - _appendingPageCount);
                        _shouldResetOffset = NO;
                        [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x - (_pages.count - _appendingPageCount) * _pageSize.width, 0) animated:NO];
                        _shouldResetOffset = YES;
                    }
                    [_scrollView setContentOffset:CGPointMake(_pageSize.width * index, 0) animated:YES];
                    [self setPagesAtContentOffset:_scrollView.contentOffset];
                    [self refreshVisiblePagesAppearance];
                }
                    break;
                case PageViewOrientationVertical:
                {
                    NSInteger index ;
                    if (pageIndex < _appendingPageCount/2) {
                        index = (_pages.count - _appendingPageCount) + pageIndex ;
                        _shouldResetOffset = NO;
                        [_scrollView setContentOffset:CGPointMake(0, _scrollView.contentOffset.y + (_pages.count - _appendingPageCount) * _pageSize.height) animated:NO];
                        _shouldResetOffset = YES;
                        
                    }else if(pageIndex < _pages.count  - _appendingPageCount/2){
                        index = pageIndex ;
                    }else{
                        index = pageIndex - (_pages.count  - _appendingPageCount);
                        _shouldResetOffset = NO;
                        [_scrollView setContentOffset:CGPointMake(0, _scrollView.contentOffset.y - (_pages.count - _appendingPageCount) * _pageSize.height) animated:NO];
                        _shouldResetOffset = YES;
                    }
                    [_scrollView setContentOffset:CGPointMake(0, _pageSize.height * index) animated:YES];
                    [self setPagesAtContentOffset:_scrollView.contentOffset];
                    [self refreshVisiblePagesAppearance];
                }
                default:
                    break;
            }
        }else {
            switch (_orientation) {
                case PageViewOrientationHorizontal:
                    [_scrollView setContentOffset:CGPointMake(_pageSize.width * pageIndex, 0) animated:YES];
                    break;
                case PageViewOrientationVertical:
                    [_scrollView setContentOffset:CGPointMake(0, _pageSize.height * pageIndex) animated:YES];
                    break;
            }
            [self setPagesAtContentOffset:_scrollView.contentOffset];
            [self refreshVisiblePagesAppearance];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Override Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initialize];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    if (_needsReload) {
        //如果需要重新加载数据，则需要清空相关数据全部重新加载
        
        //重置pageCount
        if (_dataSource && [_dataSource respondsToSelector:@selector(numberOfPagesInPageView:)]) {
            _dataSourcePageCount = [_dataSource numberOfPagesInPageView:self];
            if (!_dataSourcePageCount) {
                return;
            }
            if (_pageControl && [_pageControl respondsToSelector:@selector(setNumberOfPages:)]) {
                [_pageControl setNumberOfPages:_dataSourcePageCount];
            }
        }
        
        //重置pageWidth
        if (_delegate && [_delegate respondsToSelector:@selector(sizeForPageInPageView:)]) {
            _pageSize = [_delegate sizeForPageInPageView:self];
        }
        if (_delegate && [_delegate respondsToSelector:@selector(pageViewShouldWrap:)]) {
            _shouldWrap = [_delegate pageViewShouldWrap:self];
        }
        
        if (_shouldWrap) {
            NSInteger halfAppendingPageCount ;
            switch (_orientation) {
                case PageViewOrientationHorizontal:
                {
                    halfAppendingPageCount = (self.frame.size.width / _pageSize.width );
                    if (halfAppendingPageCount * _pageSize.width < self.frame.size.width) {
                        halfAppendingPageCount = halfAppendingPageCount + 1;
                    }
                }
                    break;
                case PageViewOrientationVertical:
                {
                    halfAppendingPageCount = (self.frame.size.height / _pageSize.height );
                    if (halfAppendingPageCount * _pageSize.height < self.frame.size.height) {
                        halfAppendingPageCount = halfAppendingPageCount + 1;
                    }
                }
                    break;
                default:
                    break;
            }
            @try {
                NSAssert(halfAppendingPageCount <= _dataSourcePageCount , @"page size is too small");
                _appendingPageCount = halfAppendingPageCount * 2;
                
            }
            @catch (NSException *exception) {
                NSLog(@"shouldWrap is set NO ! because %@",exception.reason);
                _shouldWrap = NO;
            }
        }
        
        [_reusablePages removeAllObjects];
        _visibleRange = NSMakeRange(0, 0);
        
        //填充pages数组
        [_pages removeAllObjects];
        if (_shouldWrap) {
            for (NSInteger index = 0; index < _dataSourcePageCount + _appendingPageCount; index++)
            {
                [_pages addObject:[NSNull null]];
            }
            
        }else{
            for (NSInteger index = 0; index < _dataSourcePageCount; index++)
            {
                [_pages addObject:[NSNull null]];
            }
            
        }
        NSLog(@"pagescount %d",_pages.count);
        // 重置_scrollView的contentSize
        switch (_orientation) {
            case PageViewOrientationHorizontal://横向
            {
                _scrollView.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
                _scrollView.contentSize = CGSizeMake(_pageSize.width * _pages.count,_pageSize.height);
                CGPoint theCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
                _scrollView.center = theCenter;
                _scrollView.contentOffset = CGPointMake(_shouldWrap ?
                                                        _pageSize.width *(_appendingPageCount/2 ) : 0,
                                                        0);
            }
                break;
            case PageViewOrientationVertical:
            {
                _scrollView.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
                _scrollView.contentSize = CGSizeMake(_pageSize.width ,_pageSize.height * _pages.count);
                CGPoint theCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
                _scrollView.center = theCenter;
                _scrollView.contentOffset = CGPointMake(0,
                                                        _shouldWrap ?
                                                        _pageSize.height * (_appendingPageCount/2 ) : 0);
            }
                break;
            default:
                break;
        }
    }
    [self setPagesAtContentOffset:_scrollView.contentOffset];//根据当前scrollView的offset设置page
    [self refreshVisiblePagesAppearance];
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark PageView API

- (void)reloadData
{
    _needsReload = YES;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}


- (UIView *)dequeueReusablePage{
    UIView *page = [_reusablePages lastObject] ;
    if (page)
    {
        [_reusablePages removeLastObject];
    }
    
    return page ;
}

- (void)scrollToPage:(NSInteger)pageIndex {
    
    if (pageIndex < _dataSourcePageCount){
        
        [self calculateCurrentPageIndex:_scrollView];
        //        NSLog(@"========= %d",_currentPageIndex);
        
        if (_shouldWrap) {
            switch (_orientation) {
                case PageViewOrientationHorizontal:
                {
                    NSInteger count = ((self.frame.size.width - _pageSize.width) / 2) / _pageSize.width;
                    if (count * _pageSize.width < ((self.frame.size.width - _pageSize.width) / 2)) {
                        count = count + 1;
                    }
                    NSInteger leftLimitIndex = _appendingPageCount/2 + count - 1;
                    NSInteger rightLimitIndex = _pages.count - 1 - _appendingPageCount/2 - count;
                    //                    NSLog(@"left %d,right %d",leftLimitIndex,rightLimitIndex);
                    NSInteger index  = pageIndex + _appendingPageCount/2;
                    if (rightLimitIndex > leftLimitIndex){
                        if ((_currentPageIndex <= leftLimitIndex) &&
                            (pageIndex >= _pages.count - _appendingPageCount - 1 - count)) {
                            
                            _shouldResetOffset = NO;
                            [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x + (_pages.count - _appendingPageCount) * _pageSize.width, 0) animated:NO];
                            _shouldResetOffset = YES;
                        }
                        
                        if ((_currentPageIndex >= rightLimitIndex) &&
                            pageIndex <= count - 1) {
                            _shouldResetOffset = NO;
                            [_scrollView setContentOffset:CGPointMake(_scrollView.contentOffset.x - (_pages.count - _appendingPageCount) * _pageSize.width, 0) animated:NO];
                            _shouldResetOffset = YES;
                        }
                    }
                    
                    [_scrollView setContentOffset:CGPointMake(_pageSize.width * index, 0) animated:YES];
                    NSLog(@"=========1111 %d ",_currentPageIndex);
                    [self setPagesAtContentOffset:_scrollView.contentOffset];
                    NSLog(@"=========2222 %d ",_currentPageIndex);
                    [self refreshVisiblePagesAppearance];
                    NSLog(@"=========333 %d end............",_currentPageIndex);
                    
                    
                }
                    break;
                case PageViewOrientationVertical:
                {
                    NSInteger count = ((self.frame.size.height - _pageSize.height) / 2) / _pageSize.height;
                    if (count * _pageSize.height < ((self.frame.size.height - _pageSize.height) / 2)) {
                        count = count + 1;
                    }
                    NSInteger topLimitIndex = _appendingPageCount/2 + count - 1;
                    NSInteger downLimitIndex = _pages.count - 1 - _appendingPageCount/2 - count;
                    NSInteger index  = pageIndex + _appendingPageCount/2;
                    if ((_currentPageIndex <= topLimitIndex) &&
                        (pageIndex >= _pages.count - _appendingPageCount - 1 - count)) {
                        
                        _shouldResetOffset = NO;
                        [_scrollView setContentOffset:CGPointMake(0, _scrollView.contentOffset.y + (_pages.count - _appendingPageCount) * _pageSize.height) animated:NO];
                        _shouldResetOffset = YES;
                    }
                    if ((_currentPageIndex >= downLimitIndex) &&
                        pageIndex <= count - 1) {
                        _shouldResetOffset = NO;
                        [_scrollView setContentOffset:CGPointMake(0, _scrollView.contentOffset.y - (_pages.count - _appendingPageCount) * _pageSize.height) animated:NO];
                        _shouldResetOffset = YES;
                    }
                    
                    [_scrollView setContentOffset:CGPointMake(0, _pageSize.height * index) animated:YES];
                    NSLog(@"=========444 %d ",_currentPageIndex);
                    [self setPagesAtContentOffset:_scrollView.contentOffset];
                    NSLog(@"=========555 %d ",_currentPageIndex);
                    [self refreshVisiblePagesAppearance];
                    NSLog(@"=========666 %d ",_currentPageIndex);
                }
                default:
                    break;
            }
        }else {
            switch (_orientation) {
                case PageViewOrientationHorizontal:
                    [_scrollView setContentOffset:CGPointMake(_pageSize.width * pageIndex, 0) animated:YES];
                    break;
                case PageViewOrientationVertical:
                    [_scrollView setContentOffset:CGPointMake(0, _pageSize.height * pageIndex) animated:YES];
                    break;
            }
            [self setPagesAtContentOffset:_scrollView.contentOffset];
            [self refreshVisiblePagesAppearance];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark hitTest

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self pointInside:point withEvent:event]) {
        CGPoint newPoint = CGPointZero;
        newPoint.x = point.x - _scrollView.frame.origin.x + _scrollView.contentOffset.x;
        newPoint.y = point.y - _scrollView.frame.origin.y + _scrollView.contentOffset.y;
        if ([_scrollView pointInside:newPoint withEvent:event]) {
            return [_scrollView hitTest:newPoint withEvent:event];
        }
        
        return _scrollView;
    }
    
    return nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (_shouldWrap && _shouldResetOffset) {
        //        [self calculateCurrentPageIndex:scrollView];
        NSLog(@"=---------======== %f",scrollView.contentOffset.x);
        switch (_orientation) {
            case PageViewOrientationHorizontal:
            {
                if (_currentPageIndex == _appendingPageCount/2 - 1) {
                    _scrollView.contentOffset = CGPointMake(_scrollView.contentOffset.x + _pageSize.width * (_pages.count - _appendingPageCount ), 0);
                    return;
                }
                if (_currentPageIndex == _pages.count - _appendingPageCount/2) {
                    _scrollView.contentOffset = CGPointMake(_scrollView.contentOffset.x - _pageSize.width * (_pages.count - _appendingPageCount ), 0);
                    return;
                }
                
            }
                break;
            case PageViewOrientationVertical:
            {
                if (_currentPageIndex == _appendingPageCount/2 - 1) {
                    _scrollView.contentOffset = CGPointMake(0, _scrollView.contentOffset.y + _pageSize.height * (_pages.count - _appendingPageCount ));
                    return;
                }
                if (_currentPageIndex == _pages.count - _appendingPageCount/2) {
                    _scrollView.contentOffset = CGPointMake(0, _scrollView.contentOffset.y - _pageSize.height * (_pages.count - _appendingPageCount ));
                    return;
                }
                
            }
                break;
            default:
                break;
        }
        
    }
    [self setPagesAtContentOffset:scrollView.contentOffset];
    [self refreshVisiblePagesAppearance];
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    [self calculateCurrentPageIndex:scrollView];
    NSInteger index ;
    if (_shouldWrap) {
        if (_currentPageIndex < _appendingPageCount/2) {
            index = _pages.count  - _appendingPageCount - _appendingPageCount/2 + _currentPageIndex ;
        }else if(_currentPageIndex < _pages.count  - _appendingPageCount/2){
            index = _currentPageIndex - _appendingPageCount/2;
        }else{
            index = _currentPageIndex - (_pages.count  - _appendingPageCount/2);
        }
    }
    if ([_delegate respondsToSelector:@selector(pageView:didScrollToPage:)] ) {
        [_delegate pageView:self didScrollToPage:_shouldWrap ? index :_currentPageIndex];
    }
    if (_pageControl && [_pageControl respondsToSelector:@selector(setCurrentPage:)]) {
        [_pageControl setCurrentPage:_shouldWrap ? index :_currentPageIndex];
    }
    
}

#pragma mark - tap page
- (void)didTapPage:(TapGestureRecognizer *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(pageView:didSelectPageAtIndex:)]) {
        [_delegate pageView:self didSelectPageAtIndex:sender.tapId];
    }
    if (_delegate && [_delegate respondsToSelector:@selector(pageView:shouldScrollToSelectedPage:)]) {
        if ([_delegate pageView:self shouldScrollToSelectedPage:sender.tapId]) {
            NSLog(@"id %d",sender.gestureId);
            [self scrollToSelectedPage:_shouldWrap ? sender.gestureId :sender.tapId];
        }
    }
    
}
@end


@implementation ExternalScrollView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect frame = CGRectMake(0, 0,
                              self.contentSize.width,
                              self.contentSize.height);
    
    if (CGRectContainsPoint(self.frame, point) ||
        CGRectContainsPoint(frame, point))
        return YES;
    return NO;
    
}
@end

@interface TapGestureRecognizer ()
@end
@implementation TapGestureRecognizer
@synthesize tapId = _tapId;
@synthesize gestureId = _gestureId;
@end