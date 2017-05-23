//
//  RGMPagingScrollView.h
//  RGMPagingScrollView
//
//  Created by Ryder Mackay on 12-04-20.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    NovaScrollDirectionHorizontal,
    NovaScrollDirectionVertical
} NovaScrollDirection;

@class NovaPagingScrollView;
@class NovaSegmentedControl;
#pragma mark RGMPagingScrollViewDelegate

@protocol NovaPagingScrollViewDelegate <UIScrollViewDelegate>
@optional
- (void)pagingScrollView:(NovaPagingScrollView *)pagingScrollView scrolledToPage:(NSInteger)idx;
- (void)pagingScrollView:(NovaPagingScrollView *)pagingScrollView scrolledToBonus:(BOOL)left;
@end



#pragma mark - RGMPagingScrollViewDatasource

@protocol NovaPagingScrollViewDatasource <NSObject>
@required
- (NSInteger)pagingScrollViewNumberOfPages:(NovaPagingScrollView *)pagingScrollView;
- (UIView *)pagingScrollView:(NovaPagingScrollView *)pagingScrollView viewForIndex:(NSInteger)idx;
@optional
- (NSArray*) titlesOfPages:(NovaPagingScrollView *)pagingScrollView;
@end



#pragma mark - RGMPagingScrollView

@interface NovaPagingScrollView : UIScrollView <UIScrollViewDelegate>

@property (assign, nonatomic) NovaScrollDirection scrollDirection;
@property (nonatomic, assign) CGRect headerFrame;
@property (nonatomic, strong) NovaSegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet id <NovaPagingScrollViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet id <NovaPagingScrollViewDatasource> datasource;

@property (nonatomic) NSInteger currentPage;
- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated;

- (UIView *)dequeueReusablePageWithIdentifer:(NSString *)identifier forIndex:(NSInteger)idx;
- (UIView *)currentSelectedPage;
- (UIView *)pageAtIndex:(NSInteger)idx;
- (void)registerClass:(Class)pageClass forCellReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(UINib *)nib forCellReuseIdentifier:(NSString *)identifier;

- (void)reloadData;
- (void)initHeader;
- (void)handleSegmentClicked:(id)sender;
@end



#pragma mark - UIView+RGMReusablePage

@interface UIView (NovaReusablePage)

@property (copy, nonatomic, readonly) NSString *pageReuseIdentifier;
- (void)prepareForReuse;

@end




