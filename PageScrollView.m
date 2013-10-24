//
//  PageScrollView.m
//  UtilitySDK
//
//  Created by chujian on 13-10-16.
//  Copyright (c) 2013年 chujian. All rights reserved.
//

#import "PageScrollView.h"
const CGFloat onePageWidth = 160;
@interface PageScrollView ()
{
    NSInteger currentIndex;
}
@end
@implementation PageScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame pages:(NSMutableArray *)pages
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.pagesArray = pages;
        
        self.clipsToBounds = YES;
        _scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(80, 0, 160,100)];
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = YES;
        _scrollView.scrollEnabled = YES;
        _scrollView.clipsToBounds = NO;
        _scrollView.contentSize = CGSizeMake(onePageWidth * 10, 100);
        
        
        
        for(int i = 0;i < 10;i++){
            
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [btn setFrame:CGRectMake(i * onePageWidth, 0, onePageWidth - 5, frame.size.height)];
            [btn setTitle:[NSString stringWithFormat:@"i=%d",i] forState:UIControlStateNormal];
            btn.backgroundColor = [UIColor greenColor];
            [btn addTarget:self action:@selector(tapLab:) forControlEvents:UIControlEventTouchUpInside];
            [_scrollView addSubview:btn];
        }
        
        [self addSubview:_scrollView];
    }
    return self;
}
- (void)tapLab:(id )sender
{
    NSLog(@"tag %@",sender);
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat x = scrollView.contentOffset.x;
    currentIndex = x/onePageWidth;
//    NSLog(@"scroll...");
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [UIView animateWithDuration:0.2 animations:^{
    
    
//        scrollView.contentOffset = CGPointMake(currentIndex * onePageWidth , 0);
    }];
//    NSLog(@"endDecelerating...");
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* result = nil;
    for (UIView* sub in [self.subviews reverseObjectEnumerator]) {
        CGPoint pt = [self convertPoint:point toView:sub];
        result = [sub hitTest:pt withEvent:event];
        if (result)
            return result;
    }
    return nil;
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    NSLog(@"xxx %f",point.x);
    CGFloat radius = 80;
    CGRect frame = CGRectMake(-radius, 0,
                              self.frame.size.width + radius * 2,
                              self.frame.size.height );
    
    if (CGRectContainsPoint(self.frame, point) ||
        CGRectContainsPoint(frame, point))
        return YES;
    return NO;
}
@end


@implementation MMScrollView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSLog(@"hit vvv");
    return [super hitTest:point withEvent:event];
}// recursively calls -pointInside:withEvent:. point is in the receiver's coordinate system

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    NSLog(@"p vv");
    return [super pointInside:point withEvent:event];
}

@end

@implementation AView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSLog(@"hit view aaaa");
    return nil;
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL b = [super pointInside:point withEvent:event];
    if (b) {
        NSLog(@"ppp aa");
    }
    return b;
    
//    return [super pointInside:point withEvent:event];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    NSLog(@"aaa");
}
@end

@implementation BView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSLog(@"hit view bbb");
    return self;
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    
    NSLog(@"ppp bbb");
    return [super pointInside:point withEvent:event];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    NSLog(@"bbb");
}

@end