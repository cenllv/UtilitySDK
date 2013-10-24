//
//  MScrollView.m
//  UtilitySDK
//
//  Created by chujian on 13-10-15.
//  Copyright (c) 2013年 chujian. All rights reserved.
//

#import "MScrollView.h"
@interface MScrollView()
{
    CGFloat _scrollW;
    CGFloat _scrollH;
}

@end


@implementation MScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.delegate = self;
        _scrollView.contentSize = CGSizeMake(self.bounds.size.width * 3, self.bounds.size.height);
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.contentOffset = CGPointMake(self.bounds.size.width, 0);
        _scrollView.pagingEnabled = YES;
        [self addSubview:_scrollView];
        
        CGRect rect = self.bounds;
        rect.origin.y = rect.size.height - 30;
        rect.size.height = 30;
        _pageControl = [[UIPageControl alloc] initWithFrame:rect];
        _pageControl.userInteractionEnabled = NO;
        
        [self addSubview:_pageControl];
    }
    return self;
}

-(void)setScrollView:(UIScrollView *)scrollView
{
    
}

@end
