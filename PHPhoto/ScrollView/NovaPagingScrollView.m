//
//  NovaPagingScrollView.m
//  NovaPagingScrollView
//
//  Created by Ryder Mackay on 12-04-20.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import "NovaPagingScrollView.h"
#import <objc/runtime.h>
#import "NovaSegmentedControl.h"

#pragma mark UIView + NovaReusablePage

@implementation UIView (NovaReusablePage)

static NSString *NovaPageReuseIdentifierKey = @"pageReuseIdentifier";

- (NSString *)pageReuseIdentifier
{
    return objc_getAssociatedObject(self, &NovaPageReuseIdentifierKey);
}

- (void)setPageReuseIdentifier:(NSString *)pageReuseIdentifier
{
    objc_setAssociatedObject(self, &NovaPageReuseIdentifierKey, pageReuseIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)prepareForReuse
{
    
}

@end





#pragma mark - RGMPagingScrollViewPrivateDelegate

@interface NovaPagingScrollViewPrivateDelegate : NSObject <UIScrollViewDelegate>

- (id)initWithPagingScrollView:(NovaPagingScrollView *)pagingScrollView;

@property (weak, nonatomic) NovaPagingScrollView *pagingScrollView;
@property (weak, nonatomic) id <NovaPagingScrollViewDelegate> delegate;

@end


@implementation NovaPagingScrollViewPrivateDelegate

- (id)initWithPagingScrollView:(NovaPagingScrollView *)pagingScrollView
{
    if (self = [super init]) {
        self.pagingScrollView = pagingScrollView;
    }
    
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
   // NSLog(@"call responses to selector: %@",NSStringFromSelector(aSelector));
    
    return [super respondsToSelector:aSelector] || [self.delegate respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
   // NSLog(@"try to forwarding invocation: %@", invocation);
    if ([self.delegate respondsToSelector:invocation.selector]) {
     //   NSLog(@"forwarding invocation: %@", invocation);
        [invocation invokeWithTarget:self.delegate];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.pagingScrollView scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.pagingScrollView scrollViewDidEndDecelerating:scrollView];
    
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self.pagingScrollView scrollViewDidEndScrollingAnimation:scrollView];
    
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.pagingScrollView scrollViewWillBeginDragging:scrollView];
    
    if ([self.delegate respondsToSelector:_cmd])
    {
        [self.delegate scrollViewWillBeginDragging:scrollView];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.pagingScrollView scrollViewDidScroll:scrollView];
    
    if ([self.delegate respondsToSelector:_cmd])
    {
        [self.delegate scrollViewDidScroll:scrollView];
    }
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self.pagingScrollView scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    
    if ([self.delegate respondsToSelector:_cmd])
    {
        [self.delegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

@end





#pragma mark - RGMPagingScrollViewModel

@interface NovaPagingScrollViewModel : NSObject

@property (nonatomic) NSInteger numberOfPages;
@property (nonatomic) CGFloat pageWidth;
@property (nonatomic) CGFloat pageHeight;
@property (nonatomic) CGFloat gutter;

- (CGSize)contentSizeForDirection:(NovaScrollDirection)direction;

@end



@implementation NovaPagingScrollViewModel

- (CGSize)contentSizeForDirection:(NovaScrollDirection)direction
{
    switch (direction) {
        case NovaScrollDirectionHorizontal:
            return CGSizeMake((self.pageWidth + self.gutter) * self.numberOfPages, self.pageHeight);
            break;
        case NovaScrollDirectionVertical:
            return CGSizeMake(self.pageWidth, (self.pageHeight + self.gutter) * self.numberOfPages);
            break;
        default:
            return CGSizeMake(self.pageWidth, self.pageHeight);
            break;
    }
}

@end





#pragma mark - RGMPagingScrollView

@interface NovaPagingScrollView () {
    NSMutableSet *_visiblePages;
    NSMutableDictionary *_reusablePages;
    NSMutableDictionary *_registeredClasses;
    NSMutableDictionary *_registeredNibs;
}

@property (strong, nonatomic) NovaPagingScrollViewModel *viewModel;
@property (strong, nonatomic) NovaPagingScrollViewPrivateDelegate *privateDelegate;
@property (nonatomic, assign) CGFloat scrollViewStartOffset;

- (CGRect)frameForIndex:(NSInteger)idx;
- (BOOL)isDisplayingPageAtIndex:(NSInteger)idx;
- (void)queuePageForReuse:(UIView *)page;
- (void)didScrollToPage:(NSInteger)idx;

@end


@implementation NovaPagingScrollView
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]){
        [self commonInit];
    }
    
    return self;
}

- (void)initHeader
{
    _headerFrame = CGRectMake(0, 0, 0, 0);
    
}

-(void) dealloc
{
    self.delegate = nil;
}

- (void)commonInit
{
    self.pagingEnabled = YES;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    self.scrollViewStartOffset = -1;
    
    _scrollDirection = NovaScrollDirectionHorizontal;
    _visiblePages = [NSMutableSet set];
    _reusablePages = [NSMutableDictionary dictionary];
    _registeredClasses = [NSMutableDictionary dictionary];
    _registeredNibs = [NSMutableDictionary dictionary];
    
    [self initHeader];

}

- (void)handleSegmentClicked:(id)sender
{
    [self setCurrentPage:self.segmentedControl.selectedSegmentIndex animated:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(pagingScrollView:scrolledToPage:)])
    {
        [self.delegate pagingScrollView:self scrolledToPage:self.segmentedControl.selectedSegmentIndex];
    }
}


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.clipsToBounds == NO) {
        CGPoint newPoint = [self.superview convertPoint:point fromView:self];
        return CGRectContainsPoint(self.superview.bounds, newPoint);
    }
    else {
        return [super pointInside:point withEvent:event];
    }
}

- (NovaPagingScrollViewPrivateDelegate *)privateDelegate
{
    if (_privateDelegate == nil) {
        _privateDelegate = [[NovaPagingScrollViewPrivateDelegate alloc] initWithPagingScrollView:self];
    }
    
    return _privateDelegate;
}

- (void)setDelegate:(id <NovaPagingScrollViewDelegate>)delegate
{
    self.privateDelegate.delegate = delegate;
    [super setDelegate:self.privateDelegate];
}

- (id <NovaPagingScrollViewDelegate>)delegate
{
    return self.privateDelegate.delegate;
}

- (void)reloadData
{
    for (UIView *view in _visiblePages) {
        [view removeFromSuperview];
    }
    
    [_visiblePages removeAllObjects];
    [_reusablePages removeAllObjects];
    
    self.viewModel = nil;
    
    [self setNeedsLayout];
}

- (NovaPagingScrollViewModel *)viewModel
{
    if (_viewModel == nil)
    {
        _viewModel = [[NovaPagingScrollViewModel alloc] init];
        _viewModel.numberOfPages = [self.datasource pagingScrollViewNumberOfPages:self];
        
        _viewModel.pageWidth = [UIScreen mainScreen].bounds.size.width;
        _viewModel.pageHeight = self.bounds.size.height - self.headerFrame.size.height;

        _viewModel.gutter = 0.0f;
        
        self.contentSize = [_viewModel contentSizeForDirection:self.scrollDirection];
        
        // expand view to accomodate gutter
        CGRect frame = self.frame;
        
        switch (self.scrollDirection) {
            case NovaScrollDirectionHorizontal: {
                frame.size.width += _viewModel.gutter;
                frame.origin.x -= _viewModel.gutter / 2;
                break;
            }
            case NovaScrollDirectionVertical: {
                frame.size.height += _viewModel.gutter;
                frame.origin.y -= _viewModel.gutter / 2;
                break;
            }
        }
        
        self.frame = frame;
        
        if(self.segmentedControl && self.datasource && [self.datasource respondsToSelector:@selector(titlesOfPages:)])
        {
            self.segmentedControl.sectionTitles = [self.datasource titlesOfPages:self];
        }
    }
    return _viewModel;
}

- (CGRect)frameForIndex:(NSInteger)idx
{
    NovaPagingScrollViewModel *model = self.viewModel;
    
    CGFloat pageWidth = model.pageWidth;
    CGFloat pageHeight = model.pageHeight;
    CGFloat gutter = model.gutter;
    
    CGRect frame = CGRectZero;
    frame.size.width = pageWidth;
    frame.size.height = pageHeight;
    
    switch (self.scrollDirection) {
        case NovaScrollDirectionHorizontal:
            frame.origin.x = (pageWidth + gutter) * idx + floorf(gutter / 2.0f);
            frame.origin.y = self.headerFrame.size.height;
            break;
        case NovaScrollDirectionVertical:
            frame.origin.y = (pageHeight + gutter) * idx + floorf(gutter / 2.0f);
            //TODO: support vertical mode
            break;
    }
    
    return frame;
}

- (BOOL)isDisplayingPageAtIndex:(NSInteger)idx
{
    BOOL isDisplayingPage = NO;
    
    for (UIView *page in _visiblePages) {
        if (page.tag == idx) {
            isDisplayingPage = YES;
            break;
        }
    }
    
    return isDisplayingPage;
}

- (void)registerClass:(Class)pageClass forCellReuseIdentifier:(NSString *)identifier
{
    NSParameterAssert(identifier != nil);
    
    [_registeredClasses setValue:pageClass forKey:identifier];
    [_registeredNibs removeObjectForKey:identifier];
}

- (void)registerNib:(UINib *)nib forCellReuseIdentifier:(NSString *)identifier
{
    NSParameterAssert(identifier != nil);
    
    [_registeredNibs setValue:nib forKey:identifier];
    [_registeredClasses removeObjectForKey:identifier];
}

- (UIView *)dequeueReusablePageWithIdentifer:(NSString *)identifier forIndex:(NSInteger)idx
{
    NSParameterAssert(identifier != nil);
    
    NSMutableSet *set = [self reusablePagesWithIdentifier:identifier];
    UIView *page = [set anyObject];
    
    if (page != nil) {
        [page prepareForReuse];
        [set removeObject:page];
        
        return page;
    }
    
    NSAssert([_registeredClasses.allKeys containsObject:identifier] || [_registeredNibs.allKeys containsObject:identifier], @"No registered class or nib for identifier \"%@\"", identifier);
    
    // instantiate page from registered class
    Class pageClass = [_registeredClasses objectForKey:identifier];
    page = [[pageClass alloc] initWithFrame:CGRectZero];
    
    if (page == nil) {
        // otherwise, instantiate from registered nib
        UINib *registeredNib = [_registeredNibs objectForKey:identifier];
        
        NSArray *topLevelObjects = [registeredNib instantiateWithOwner:self options:nil];
        NSParameterAssert(topLevelObjects.count == 1);
        
        page = [topLevelObjects objectAtIndex:0];
        NSParameterAssert([page isKindOfClass:[UIView class]]);
    }
    
    page.pageReuseIdentifier = identifier;
    
    return page;
}

-(UIView*) currentSelectedPage
{
    return [self pageAtIndex:self.currentPage];
}

-(UIView*) pageAtIndex:(NSInteger)idx
{
    for (UIView * view in _visiblePages)
    {
        if (view.tag == idx)
        {
            return view;
        }
    }
    
    return nil;
}

- (NSMutableSet *)reusablePagesWithIdentifier:(NSString *)identifier
{
    if (identifier == nil) {
        return nil;
    }
    
    NSMutableSet *set = [_reusablePages objectForKey:identifier];
    if (set == nil) {
        set = [NSMutableSet set];
        [_reusablePages setObject:set forKey:identifier];
    }
    
    return set;
}

- (void)queuePageForReuse:(UIView *)page
{
    if (page.pageReuseIdentifier == nil) {
        return;
    }
    
    [[self reusablePagesWithIdentifier:page.pageReuseIdentifier] addObject:page];
}

-(void)setHeaderFrame:(CGRect)headerFrame
{
    _headerFrame = headerFrame;
}

- (void)layoutSubviews
{
    
    [super layoutSubviews];
    
    // calculate needed indexes
    CGFloat numberOfPages = self.viewModel.numberOfPages;
    CGRect visibleBounds = self.clipsToBounds ? self.bounds : [self convertRect:self.superview.bounds fromView:self.superview];
    CGFloat pageLength, min, max;
    
    switch (self.scrollDirection) {
        case NovaScrollDirectionHorizontal: {
            pageLength = self.viewModel.pageWidth + self.viewModel.gutter;
            min = CGRectGetMinX(visibleBounds) + self.viewModel.gutter / 2;
            max = CGRectGetMaxX(visibleBounds) - self.viewModel.gutter / 2;
            break;
        }
        case NovaScrollDirectionVertical: {
            pageLength = self.viewModel.pageHeight + self.viewModel.gutter;
            min = CGRectGetMinY(visibleBounds) + self.viewModel.gutter / 2;
            max = CGRectGetMaxY(visibleBounds) - self.viewModel.gutter / 2;
            break;
        }
    }
    
    max--;
    
    NSInteger firstNeededIndex = floorf(min / pageLength);
    NSInteger lastNeededIndex = floorf(max / pageLength);
    
    firstNeededIndex = MAX(firstNeededIndex, 0);
    lastNeededIndex = MIN(numberOfPages - 1, lastNeededIndex);
    
    
    
    // remove and queue reusable pages
    NSMutableSet *removedPages = [NSMutableSet set];
    
    for (UIView *visiblePage in _visiblePages) {
        if (visiblePage.tag < firstNeededIndex || visiblePage.tag > lastNeededIndex) {
            [visiblePage removeFromSuperview];
            [removedPages addObject:visiblePage];
            [self queuePageForReuse:visiblePage];
        }
    }
    
    [_visiblePages minusSet:removedPages];
    
    

    // layout visible pages
    if (numberOfPages > 0) {
        for (NSInteger idx = firstNeededIndex; idx <= lastNeededIndex; idx++) {
            if ([self isDisplayingPageAtIndex:idx] == NO) {
                UIView *page = [self.datasource pagingScrollView:self viewForIndex:idx];
                NSParameterAssert(page != nil);
                
                page.frame = [self frameForIndex:idx];
                page.tag = idx;
                [self insertSubview:page atIndex:0];
                [_visiblePages addObject:page];
            }
        }
    }
    [self positionSegmentedControl];
}


-(void) positionSegmentedControl
{
    CGRect frame = self.headerFrame;
    if (self.segmentedControl == nil)
    {
        return;
    }
    
    // The origin should be exactly like the content offset so it would look like
    // the shadow is at the top of the table (when it's actually just part of the content)
    frame.origin = CGPointMake(self.contentOffset.x, 0);
    self.segmentedControl.frame = frame;
    
    if (self.segmentedControl.superview == nil)
    {
        [self addSubview:self.segmentedControl];
    }
    [self bringSubviewToFront:self.segmentedControl];
}


- (NSInteger)currentPage
{
    NSInteger currentPage;
    
    switch (self.scrollDirection) {
        case NovaScrollDirectionHorizontal: {
            CGFloat pageWidth = self.viewModel.pageWidth + self.viewModel.gutter;
            currentPage = floorf(CGRectGetMinX(self.bounds) / pageWidth);
            break;
        }
        case NovaScrollDirectionVertical: {
            CGFloat pageHeight = self.viewModel.pageHeight + self.viewModel.gutter;
            currentPage = floorf(CGRectGetMinY(self.bounds) / pageHeight);
            break;
        }
    }
    
    currentPage = MAX(currentPage, 0);
    currentPage = MIN((self.viewModel.numberOfPages - 1), currentPage);
    return currentPage;
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    [self setCurrentPage:currentPage animated:NO];
}

- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated
{
    CGRect frame = [self frameForIndex:currentPage];
    CGPoint offset = frame.origin;
    
    switch (self.scrollDirection) {
        case NovaScrollDirectionHorizontal:
            offset.x -= self.viewModel.gutter / 2;
            offset.y = 0;
            break;
        case NovaScrollDirectionVertical:
            offset.y -= self.viewModel.gutter / 2;
            break;
    }
    
    [self setContentOffset:offset animated:animated];
}



#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate == NO) {
        [self didScrollToPage:self.currentPage];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self didScrollToPage:self.currentPage];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self didScrollToPage:self.currentPage];
}

- (void)didScrollToPage:(NSInteger)idx
{
    if ([self.delegate respondsToSelector:@selector(pagingScrollView:scrolledToPage:)]) {
        [self.delegate pagingScrollView:self scrolledToPage:idx];
    }
}


-(NSInteger) pageIndexOfScrollView:(CGFloat)xOffset
{
    int page = xOffset / self.frame.size.width;
    return page;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.segmentedControl beginDragging:[self pageIndexOfScrollView:scrollView.contentOffset.x]];
    self.scrollViewStartOffset = scrollView.contentOffset.x;
}

-(void) reportScrollViewDidScrollToBonus:(BOOL)toBouns
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(pagingScrollView:scrolledToBonus:)])
    {
        [self.delegate pagingScrollView:self scrolledToBonus:toBouns];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x <=0 )
    {
        // scroll view to left bonus
        
        if (self.scrollViewStartOffset == 0)
        {
            [self reportScrollViewDidScrollToBonus:YES];
        }
        
        return;
    }
    
    if (scrollView.contentOffset.x >= (scrollView.contentSize.width - self.viewModel.pageWidth))
    {
        // scroll view to right bonus
        
        if (self.scrollViewStartOffset == (self.viewModel.numberOfPages -1) * self.viewModel.pageWidth)
        {
           
            [self reportScrollViewDidScrollToBonus:NO];
        }
        return;
    }
    
    CGFloat percent = (scrollView.contentOffset.x - self.scrollViewStartOffset) / scrollView.frame.size.width;
    //NSLog(@"scroll offset: %f, %f, %f",  scrollView.contentOffset.x, scrollView.contentOffset.y, percent);

    [self.segmentedControl dragging:percent];
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    //NSLog(@"end dragging: %f, %f", targetContentOffset->x, targetContentOffset->y);
    [self.segmentedControl endDragging:[self pageIndexOfScrollView:targetContentOffset->x]];
    self.scrollViewStartOffset = -1;
}


@end
