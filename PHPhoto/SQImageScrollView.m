//
//  SQImageScrollView.m
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import "SQImageScrollView.h"

#define BLUR_ITERATION 2
#define BLUR_RADIUS 230.

@interface SQImageScrollView()
@property (nonatomic, strong) UITapGestureRecognizer* doubleTapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer* singleTapGestureRecognizer;
@property (nonatomic, strong) UIActivityIndicatorView* activityView;
@property (nonatomic, strong) UIScrollView* scrollView;
@property (nonatomic, strong) UIImageView* blurView;
@property (nonatomic) BOOL isZoomingAboveOriginalSizeEnabled;
@property (nonatomic) CGFloat maximumScale;

@property (nonatomic, strong) UILongPressGestureRecognizer* longPressGestureRecognizer;

@end

@implementation SQImageScrollView

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        //        _blurView = [[UIImageView alloc] initWithFrame:self.bounds];
        //        [self addSubview:_blurView];
        
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.delegate = self;
        
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        
        // Photo viewers should feel sticky when you're panning around, not smooth and slippery
        // like a UITableView.
        _scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        
        // Ensure that empty areas of the scroll view are draggable.
        self.backgroundColor = [UIColor clearColor];
        _scrollView.backgroundColor = self.backgroundColor;
        
        //_scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleHeight);
        
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        
        [_scrollView addSubview:_imageView];
        [self addSubview:_scrollView];
        self.backgroundColor = [UIColor blackColor];
        self.isZoomingAboveOriginalSizeEnabled = YES;
        self.maximumScale = 2;
        
        _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
        _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        [self addGestureRecognizer:_doubleTapGestureRecognizer];
        
        _singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSingleTap:)];
        _singleTapGestureRecognizer.numberOfTapsRequired = 1;
        [_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
        [self addGestureRecognizer:_singleTapGestureRecognizer];
        
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
        [self addGestureRecognizer:_longPressGestureRecognizer];
        
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_activityView sizeToFit];
        //_activityView.autoresizingMask = UIViewAutoresizingFlexibleMargins;
        [self addSubview:_activityView];
    }
    
    return self;
}

#pragma mark - UIScrollViewDelegate

-(UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}


-(void) scrollViewDidZoom:(UIScrollView *)scrollView
{
    // setZoomScale会导致 scrollView.contentSIze 发生变化，当缩小的时候，contentSize.width 会变为 [UIScreen mainScreen].bounds.size.width
    // 但是由于 float 类型的计算有精度损失, 会导致 scrollView.contentSIze.width 略大于 [UIScreen mainScreen].bounds.size.width, 比如说，
    // 在 iPhone 6 plus 下:
    // [UIScreen mainScreen].bounds.size.width = 414
    // scrollView.contentSIze.width = 414.00000000000023
    // 这会导致无法左右滑动
    // 所以我们将 scrollView.contentSIze.width 重设为 [UIScreen mainScreen].bounds.size.width
    if (fabs(scrollView.contentSize.width - [UIScreen mainScreen].bounds.size.width) <= FLT_EPSILON)
    {
        scrollView.contentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, scrollView.contentSize.height);
    }
    [self centerImageView];
}

-(void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    //[_scrollView centerZoomingSubView];
    
}

#pragma mark - UIScrollView Zooming

- (CGFloat)scaleForSize:(CGSize)size boundsSize:(CGSize)boundsSize useMinimalScale:(BOOL)minimalScale {
    CGFloat xScale = boundsSize.width / size.width;   // The scale needed to perfectly fit the image width-wise.
    CGFloat yScale = boundsSize.height / size.height; // The scale needed to perfectly fit the image height-wise.
    CGFloat minScale = minimalScale ? MIN(xScale, yScale) : MAX(xScale, yScale); // Use the minimum of these to allow the image to become fully visible, or the maximum to get fullscreen size
    
    return minScale;
}

/**
 * Calculate the min and max scale for the given dimensions and photo size.
 *
 * minScale will fit the photo to the bounds, unless it is too small in which case it will
 * show the image at a 1-to-1 resolution.
 *
 * maxScale will be whatever value shows the image at a 1-to-1 resolution, UNLESS
 * isZoomingAboveOriginalSizeEnabled is enabled, in which case maxScale will be calculated
 * such that the image completely fills the bounds.
 *
 * Exception:  If the photo size is unknown (this is a loading image, for example) then
 * the minimum scale will be set without considering the screen scale. This allows the
 * loading image to draw with its own image scale if it's a high-res @2x image.
 */
- (void)minAndMaxScaleForDimensions: (CGSize)dimensions
                         boundsSize: (CGSize)boundsSize
                         photoScale: (CGFloat)photoScale
                           minScale: (CGFloat *)pMinScale
                           maxScale: (CGFloat *)pMaxScale {
    //NIDASSERT(nil != pMinScale);
    // NIDASSERT(nil != pMaxScale);
    if (nil == pMinScale
        || nil == pMaxScale) {
        return;
    }
    
    CGFloat minScale = [self scaleForSize: dimensions
                               boundsSize: boundsSize
                          useMinimalScale: YES];
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    // On high resolution screens we have double the pixel density, so we will be seeing
    // every pixel if we limit the maximum zoom scale to 0.5.
    // If the photo size is unknown, it's likely that we're showing the loading image and
    // don't want to shrink it down with the zoom because it should be a scaled image.
    CGFloat maxScale = (photoScale / scale);
    
    
    // At this point if the image is small, then minScale and maxScale will be the same because
    // we don't want to allow the photo to be zoomed.
    
    // If zooming above the original size IS enabled, however, expand the max zoom to
    // whatever value would make the image fit the view perfectly.
    if ([self isZoomingAboveOriginalSizeEnabled]) {
        CGFloat idealMaxScale = [self scaleForSize: dimensions
                                        boundsSize: boundsSize
                                   useMinimalScale: NO];
        maxScale = MAX(maxScale, idealMaxScale);
    }
    maxScale = ceilf(maxScale*10) / 10;  //get two decimal floored float value. For example, 37.7682839273 will get the result: 37.7
    *pMinScale = minScale;
    *pMaxScale = maxScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    CGSize imageSize = _imageView.bounds.size;
    
    // Avoid crashing if the image has no dimensions.
    if (imageSize.width <= 0 || imageSize.height <= 0)
    {
        _scrollView.maximumZoomScale = 1;
        _scrollView.minimumZoomScale = 1;
        return;
    }
    
    // The following code is from Apple's ImageScrollView example application and has been used
    // here because it is well-documented and concise.
    
    CGSize boundsSize = _scrollView.bounds.size;
    
    CGFloat minScale = 0;
    CGFloat maxScale = 0;
    
    // Calculate the min/max scale for the image to be presented.
    [self minAndMaxScaleForDimensions: imageSize
                           boundsSize: boundsSize
                           photoScale: _imageView.image.scale
                             minScale: &minScale
                             maxScale: &maxScale];
    
    
    // If zooming is disabled then we flatten the range for zooming to only allow the min zoom.
    
    //Why?
    if ( self.maximumScale > maxScale) {
        _scrollView.maximumZoomScale = self.maximumScale;
    } else {
        _scrollView.maximumZoomScale =  maxScale ;
    }
    _scrollView.minimumZoomScale = minScale;
}

#pragma mark - Gesture Recognizers


- (CGRect)rectAroundPoint:(CGPoint)point atZoomScale:(CGFloat)zoomScale
{
    //NIDASSERT(zoomScale > 0);
    
    // Define the shape of the zoom rect.
    CGSize boundsSize = self.bounds.size;
    
    // Modify the size according to the requested zoom level.
    // For example, if we're zooming in to 0.5 zoom, then this will increase the bounds size
    // by a factor of two.
    CGSize scaledBoundsSize = CGSizeMake(boundsSize.width / zoomScale,
                                         boundsSize.height / zoomScale);
    
    CGRect rect = CGRectMake(point.x - scaledBoundsSize.width / 2,
                             point.y - scaledBoundsSize.height / 2,
                             scaledBoundsSize.width,
                             scaledBoundsSize.height);
    
    // When the image is zoomed out there is a bit of empty space around the image due
    // to the fact that it's centered on the screen. When we created the rect around the
    // point we need to take this "space" into account.
    
    // 1: get the frame of the image in this view's coordinates.
    CGRect imageScaledFrame = [self convertRect:_imageView.frame toView:self];
    
    // 2: Offset the frame by the excess amount. This will ensure that the zoomed location
    //    is always centered on the tap location. We only allow positive values because a
    //    negative value implies that there isn't actually any offset.
    rect = CGRectOffset(rect, -MAX(0, imageScaledFrame.origin.x), -MAX(0, imageScaledFrame.origin.y));
    
    return rect;
}

- (void)didDoubleTap:(UITapGestureRecognizer *)tapGesture
{
    BOOL isCompletelyZoomedIn = (fabs(_scrollView.maximumZoomScale - _scrollView.zoomScale) <= FLT_EPSILON);
    
    //BOOL didZoomIn;
    
    if (isCompletelyZoomedIn)
    {
        // Zoom the photo back out.
        [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
        
        //didZoomIn = NO;
        
    }
    else
    {
        // Zoom into the tap point.
        CGPoint tapCenter = [tapGesture locationInView:_imageView];
        
        CGRect maxZoomRect = [self rectAroundPoint:tapCenter atZoomScale:_scrollView.maximumZoomScale];
        [_scrollView zoomToRect:maxZoomRect animated:YES];
        
        //didZoomIn = YES;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(imageScrollView:numberOfTaps:)])
    {
        [self.delegate imageScrollView:self numberOfTaps:2];
    }
}


-(void)didSingleTap:(UITapGestureRecognizer*)tapGesture
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(imageScrollView:numberOfTaps:)])
    {
        [self.delegate imageScrollView:self numberOfTaps:1];
    }
}

-(void)didLongPress:(UILongPressGestureRecognizer *)longPressGesture
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(imageScrollView:numberOfTaps:)])
    {
        [self.delegate imageScrollView:self numberOfTaps:3];
    }
}


#pragma mark - Blur image View
-(void) configBlurViewWithShowBlur:(BOOL)showBlur thumbnail:(UIImage*)thumbnail
{
    if (showBlur)
    {
        self.blurView.hidden = NO;
        if (thumbnail != nil)
        {
            //Do not support
            //self.blurView.image = [thumbnail blurredImageWithRadius:BLUR_RADIUS iterations:BLUR_ITERATION tintColor:[UIColor blackColor]];
        }
    }
    else
    {
        self.blurView.hidden = YES;
        self.blurView.image = nil;
    }
    
}

-(void) stopLoading
{
    [self.activityView stopAnimating];
    self.activityView.hidden = YES;
}

-(void) startLoading
{
    self.activityView.hidden = NO;
    [self.activityView startAnimating];
}



- (void)setImageViewWithImage:(UIImage *)image thumbnailImage:(UIImage *)thumbnailImage needBlur:(BOOL)needBlur
{
    //NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    self.imageView.image = image;
    if (image == nil)
    {
        return;
    }
    
    CGFloat scale = image.size.width / image.size.height;
    CGFloat imageFitWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat imageFitHeight = imageFitWidth / scale;
    if (imageFitHeight > [UIScreen mainScreen].bounds.size.height)
    {
        imageFitHeight = [UIScreen mainScreen].bounds.size.height;
        imageFitWidth = imageFitHeight * scale;
    }
    
    self.imageView.frame = CGRectMake(0, 0, imageFitWidth, imageFitHeight);
    [self setMaxMinZoomScalesForCurrentBounds];
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    self.scrollView.contentSize = self.bounds.size;
    [self centerImageView];
    //NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
#ifdef DEBUG
    // NSLog(@"set image view cost: %.2f", end - start);
#endif
    
}

-(void)setImageViewWiththumbnailImage:(UIImage *)thumbnailImage needBlur:(BOOL)needBlur
{
    self.imageView.image = thumbnailImage;
    if (thumbnailImage == nil)
    {
        return;
    }
    
    CGFloat scale = thumbnailImage.size.width / thumbnailImage.size.height;
    CGFloat imageFitWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat imageFitHeight = imageFitWidth / scale;
    if (imageFitHeight > [UIScreen mainScreen].bounds.size.height)
    {
        imageFitHeight = [UIScreen mainScreen].bounds.size.height;
        imageFitWidth = imageFitHeight * scale;
    }
    //If set image is thumbnail image, zooming is not allowed
    _scrollView.maximumZoomScale = 1;
    _scrollView.minimumZoomScale = 1;
    self.imageView.frame = CGRectMake(0, 0, imageFitWidth, imageFitHeight);
    [self centerImageView];
}

-(void) configViewWithImage:(UIImage *)image thumbnail:(UIImage*)thumbnailImage needBlur:(BOOL)needBlur
{
    [self setImageViewWithImage:image thumbnailImage:thumbnailImage needBlur:needBlur];
    [self stopLoading];
}

- (void)configViewWithImage:(UIImage *)image thumbnail:(UIImage*)thumbnailImage frame:(CGRect)frame needBlur:(BOOL)needBlur
{
    self.frame = frame;
    self.scrollView.frame = frame;
    //    self.blurView.frame = frame;
    
    CGSize size = self.activityView.frame.size;
    self.activityView.frame = CGRectMake( (frame.size.width - size.width)/2,  (frame.size.height - size.height)/2, size.width, size.height);
    if (image != nil)
    {
        [self setImageViewWithImage:image thumbnailImage:thumbnailImage needBlur:needBlur];
        [self stopLoading];
    }
    else
    {
        self.scrollView.zoomScale = 1;
        self.scrollView.contentSize = self.bounds.size;
        [self setImageViewWiththumbnailImage:thumbnailImage needBlur:needBlur];
        
        //        [self configBlurViewWithShowBlur:NO thumbnail:nil];
        [self startLoading];
    }
}

-(void) centerImageView
{
    UIView* zoomingSubview = self.imageView;
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = zoomingSubview.frame;
    
    // Center horizontally.
    if ( frameToCenter.size.width - boundsSize.width < 0) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2);
        
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Center vertically.
    if ( frameToCenter.size.height - boundsSize.height < 0 ) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2);
        
    } else {
        frameToCenter.origin.y = 0;
    }
    
    zoomingSubview.frame = frameToCenter;
}


@end
