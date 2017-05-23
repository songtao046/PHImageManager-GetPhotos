//
//  SQImageScrollView.h
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>

@class SQImageScrollView;


@protocol SQImageScrollViewDelegate <NSObject>

@optional
-(void) imageScrollView:(SQImageScrollView*)imageScrollView numberOfTaps:(NSInteger)numberOfTaps;


@end

@interface SQImageScrollView : UIView <UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic) id<SQImageScrollViewDelegate> delegate;
@property (nonatomic) NSInteger index;

-(void) configBlurViewWithShowBlur:(BOOL)showBlur thumbnail:(UIImage*)thumbnail;
-(void) configViewWithImage:(UIImage*)image thumbnail:(UIImage*)thumbnailImage needBlur:(BOOL)needBlur;
-(void) configViewWithImage:(UIImage*)image thumbnail:(UIImage*)thumbnailImage frame:(CGRect)frame needBlur:(BOOL)needBlur;
@end
