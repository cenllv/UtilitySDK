//
//  PageScrollView.h
//  UtilitySDK
//
//  Created by chujian on 13-10-16.
//  Copyright (c) 2013年 chujian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMScrollView : UIScrollView

@end

@interface PageScrollView : UIView <UIScrollViewDelegate>

@property (nonatomic,strong) UIScrollView * scrollView;
@property (nonatomic,strong)  NSMutableArray *pagesArray;

- (id)initWithFrame:(CGRect)frame pages:(NSMutableArray *)pages;
@end


@interface AView : UIView

@end

@interface BView : UIView

@end