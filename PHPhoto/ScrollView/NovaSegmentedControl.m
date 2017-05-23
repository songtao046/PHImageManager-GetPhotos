//
//  NovaSegmentedControl.m
//  NovaSegmentedControl
//
//  Created by Hesham Abd-Elmegid on 23/12/12.
//  Copyright (c) 2012 Hesham Abd-Elmegid. All rights reserved.
//

#import "NovaSegmentedControl.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

#define segmentImageTextPadding 7

@interface HMScrollView : UIScrollView
@end

@interface NovaSegmentedControl ()

@property (nonatomic, strong) CALayer *selectionIndicatorStripLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorBoxLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorArrowLayer;
@property (nonatomic, strong) CAShapeLayer* selectionIndicatorArrowShapeLayer;
@property (nonatomic, strong) NSMutableArray *textLayers;
@property (nonatomic, readwrite) CGFloat segmentWidth;
@property (nonatomic, readwrite) NSArray *segmentWidthsArray;
@property (nonatomic, strong) HMScrollView *scrollView;
@property (nonatomic, assign) BOOL isDraggingBegin;
@property (nonatomic, assign) CGFloat draggingStartOffset;

@end

@implementation HMScrollView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        [self.nextResponder touchesBegan:touches withEvent:event];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if (!self.dragging) {
        [self.nextResponder touchesMoved:touches withEvent:event];
    } else{
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        [self.nextResponder touchesEnded:touches withEvent:event];
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

@end

@implementation NovaSegmentedControl

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithSectionTitles:(NSArray *)sectiontitles {
    self = [self initWithFrame:CGRectZero];
    
    if (self) {
        [self commonInit];
        self.sectionTitles = sectiontitles;
        self.type = NovaSegmentedControlTypeText;
    }
    
    return self;
}

- (id)initWithSectionImages:(NSArray*)sectionImages sectionSelectedImages:(NSArray*)sectionSelectedImages {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        [self commonInit];
        self.sectionImages = sectionImages;
        self.sectionSelectedImages = sectionSelectedImages;
        self.type = NovaSegmentedControlTypeImages;
    }
    
    return self;
}

- (instancetype)initWithSectionImages:(NSArray *)sectionImages sectionSelectedImages:(NSArray *)sectionSelectedImages titlesForSections:(NSArray *)sectiontitles {
	self = [super initWithFrame:CGRectZero];
    
    if (self) {
        [self commonInit];
		
		if (sectionImages.count != sectiontitles.count) {
			[NSException raise:NSRangeException format:@"***%s: Images bounds (%ld) Dont match Title bounds (%ld)", sel_getName(_cmd), (unsigned long)sectionImages.count, (unsigned long)sectiontitles.count];
        }
		
        self.sectionImages = sectionImages;
        self.sectionSelectedImages = sectionSelectedImages;
		self.sectionTitles = sectiontitles;
        self.type = NovaSegmentedControlTypeTextImages;
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.segmentWidth = 0.0f;
    [self commonInit];
}

- (void)commonInit {
    self.scrollView = [[HMScrollView alloc] init];
    self.scrollView.scrollsToTop = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:self.scrollView];
    
    self.font = [UIFont fontWithName:@"STHeitiSC-Light" size:18.0f];
    self.textColor = [UIColor blackColor];
    self.selectedTextColor = [UIColor blackColor];
    self.backgroundColor = [UIColor colorWithRed:250 green:250 blue:250 alpha:0.5]; //[UIColor whiteColor];
    self.opaque = NO;
    self.selectionIndicatorColor = [UIColor colorWithRed:52.0f/255.0f green:181.0f/255.0f blue:229.0f/255.0f alpha:1.0f];
    
    self.selectedSegmentIndex = 0;
    self.segmentEdgeInset = UIEdgeInsetsMake(0, 5, 0, 5);
    self.selectionIndicatorHeight = 5.0f;
    self.selectionStyle = NovaSegmentedControlSelectionStyleTextWidthStripe;
    self.selectionIndicatorLocation = NovaSegmentedControlSelectionIndicatorLocationUp;
    self.segmentWidthStyle = NovaSegmentedControlSegmentWidthStyleFixed;
    self.userDraggable = YES;
    self.touchEnabled = YES;
    self.type = NovaSegmentedControlTypeText;
    
    self.shouldAnimateUserSelection = YES;
    
    self.selectionIndicatorArrowLayer = [CALayer layer];
    self.selectionIndicatorArrowShapeLayer = [CAShapeLayer layer];
    [self.selectionIndicatorArrowLayer addSublayer:self.selectionIndicatorArrowShapeLayer];

    self.selectionIndicatorStripLayer = [CALayer layer];
    
    self.selectionIndicatorBoxLayer = [CALayer layer];
    self.selectionIndicatorBoxLayer.opacity = 1;
    self.selectionIndicatorBoxLayer.borderWidth = 1.0f;
    self.selectionIndicatorBoxLayer.cornerRadius = 12.5f;
    
    self.contentMode = UIViewContentModeRedraw;
    
    self.textLayers = [NSMutableArray array];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateSegmentsRects];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self updateSegmentsRects];
}

- (void)setSectionTitles:(NSArray *)sectionTitles {
    _sectionTitles = sectionTitles;
    
    [self setNeedsLayout];
}



- (void)setSectionImages:(NSArray *)sectionImages {
    _sectionImages = sectionImages;
    
    [self setNeedsLayout];
}

- (void)setSelectionIndicatorLocation:(NovaSegmentedControlSelectionIndicatorLocation)selectionIndicatorLocation {
	_selectionIndicatorLocation = selectionIndicatorLocation;
	
	if (selectionIndicatorLocation == NovaSegmentedControlSelectionIndicatorLocationNone) {
		self.selectionIndicatorHeight = 0.0f;
	}
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    
    [self.backgroundColor setFill];
    UIRectFill([self bounds]);
    
    self.selectionIndicatorArrowLayer.backgroundColor = [UIColor whiteColor].CGColor; //self.selectionIndicatorColor.CGColor;
    
    self.selectionIndicatorStripLayer.backgroundColor = self.selectionIndicatorColor.CGColor;
    
    self.selectionIndicatorBoxLayer.backgroundColor = self.selectionIndicatorColor.CGColor;
    self.selectionIndicatorBoxLayer.borderColor = self.selectionIndicatorColor.CGColor;
    
    // Remove all sublayers to avoid drawing images over existing ones
    self.scrollView.layer.sublayers = nil;
    
    if (self.type == NovaSegmentedControlTypeText) {
        [self.textLayers removeAllObjects];
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
            CGFloat stringHeight = ceilf([titleString sizeWithAttributes:@{NSFontAttributeName: self.font}].height);
            CGFloat stringWidth = ceilf([titleString sizeWithAttributes:@{NSFontAttributeName: self.font}].width);
#else
            CGFloat stringHeight = roundf([titleString sizeWithFont:self.font].height);
            CGFloat stringWidth = roundf([titleString sizeWithFont:self.font].width);
#endif
            
            // Text inside the CATextLayer will appear blurry unless the rect values are rounded
            CGFloat y = roundf(CGRectGetHeight(self.frame) - self.selectionIndicatorHeight)/2 - stringHeight/2 + ((self.selectionIndicatorLocation == NovaSegmentedControlSelectionIndicatorLocationUp) ? self.selectionIndicatorHeight : 0);
            
            CGRect rect = CGRectZero;
            if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleFixed) {
                rect = CGRectMake((self.segmentWidth * idx) + (self.segmentWidth - stringWidth)/2, y, stringWidth, stringHeight);
            } else if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleDynamic) {
                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
                CGFloat xOffset = 0;
                NSInteger i = 0;
                for (NSNumber *width in self.segmentWidthsArray) {
                    if (idx == i)
                        break;
                    xOffset = xOffset + [width floatValue];
                    i++;
                }
                
                rect = CGRectMake(xOffset, y, [[self.segmentWidthsArray objectAtIndex:idx] floatValue], stringHeight);
            }
            
            CATextLayer *titleLayer = [CATextLayer layer];
            titleLayer.frame = rect;
            titleLayer.font = (__bridge CFTypeRef)(self.font.fontName);
            titleLayer.fontSize = self.font.pointSize;
            titleLayer.alignmentMode = kCAAlignmentCenter;
            titleLayer.string = titleString;
            titleLayer.truncationMode = kCATruncationEnd;
            
            if (self.selectedSegmentIndex == idx) {
                titleLayer.foregroundColor = self.selectedTextColor.CGColor;
            } else {
                titleLayer.foregroundColor = self.textColor.CGColor;
            }
            
            titleLayer.contentsScale = [[UIScreen mainScreen] scale];
            [self.textLayers addObject:titleLayer];
            [self.scrollView.layer addSublayer:titleLayer];
        }];
    } else if (self.type == NovaSegmentedControlTypeImages) {
        [self.sectionImages enumerateObjectsUsingBlock:^(id iconImage, NSUInteger idx, BOOL *stop) {
            UIImage *icon = iconImage;
            CGFloat imageWidth = icon.size.width;
            CGFloat imageHeight = icon.size.height;
            CGFloat y = roundf(CGRectGetHeight(self.frame) - self.selectionIndicatorHeight) / 2 - imageHeight / 2 + ((self.selectionIndicatorLocation == NovaSegmentedControlSelectionIndicatorLocationUp) ? self.selectionIndicatorHeight : 0);
            CGFloat x = self.segmentWidth * idx + (self.segmentWidth - imageWidth)/2.0f;
            CGRect rect = CGRectMake(x, y, imageWidth, imageHeight);
            
            CALayer *imageLayer = [CALayer layer];
            imageLayer.frame = rect;
            
            if (self.selectedSegmentIndex == idx) {
                if (self.sectionSelectedImages) {
                    UIImage *highlightIcon = [self.sectionSelectedImages objectAtIndex:idx];
                    imageLayer.contents = (id)highlightIcon.CGImage;
                } else {
                    imageLayer.contents = (id)icon.CGImage;
                }
            } else {
                imageLayer.contents = (id)icon.CGImage;
            }
            
            [self.scrollView.layer addSublayer:imageLayer];
        }];
    } else if (self.type == NovaSegmentedControlTypeTextImages){
		[self.sectionImages enumerateObjectsUsingBlock:^(id iconImage, NSUInteger idx, BOOL *stop) {
            // When we have both an image and a title, we start with the image and use segmentImageTextPadding before drawing the text.
            // So the image will be left to the text, centered in the middle
            UIImage *icon = iconImage;
            CGFloat imageWidth = icon.size.width;
            CGFloat imageHeight = icon.size.height;
            
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
            CGFloat stringHeight = ceilf([self.sectionTitles[idx] sizeWithAttributes:@{NSFontAttributeName: self.font}].height);
#else
			CGFloat stringHeight = roundf([self.sectionTitles[idx] sizeWithFont:self.font].height);
#endif
            CGFloat yOffset = roundf(CGRectGetHeight(self.frame) - self.selectionIndicatorHeight) / 2 - stringHeight / 2 + ((self.selectionIndicatorLocation == NovaSegmentedControlSelectionIndicatorLocationUp) ? self.selectionIndicatorHeight : 0);
            CGFloat imageXOffset = self.segmentEdgeInset.left; // Start with edge inset
            if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleFixed)
                imageXOffset = self.segmentWidth * idx;
            else if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleDynamic) {
                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
                NSInteger i = 0;
                for (NSNumber *width in self.segmentWidthsArray) {
                    if (idx == i)
                        break;
                    imageXOffset = imageXOffset + [width floatValue];
                    i++;
                }
            }
            
            CGRect imageRect = CGRectMake(imageXOffset, yOffset, imageWidth, imageHeight);
			
            // Use the image offset and padding to calculate the text offset
            CGFloat textXOffset = imageXOffset + imageWidth + segmentImageTextPadding;
            
            // The text rect's width is the segment width without the image, image padding and insets
            CGRect textRect = CGRectMake(textXOffset, yOffset, [[self.segmentWidthsArray objectAtIndex:idx] floatValue]-imageWidth-segmentImageTextPadding-self.segmentEdgeInset.left-self.segmentEdgeInset.right, stringHeight);
            CATextLayer *titleLayer = [CATextLayer layer];
            titleLayer.frame = textRect;
            titleLayer.font = (__bridge CFTypeRef)(self.font.fontName);
            titleLayer.fontSize = self.font.pointSize;
            titleLayer.alignmentMode = kCAAlignmentCenter;
            titleLayer.string = self.sectionTitles[idx];
            titleLayer.truncationMode = kCATruncationEnd;
			
            CALayer *imageLayer = [CALayer layer];
            imageLayer.frame = imageRect;
			
            if (self.selectedSegmentIndex == idx) {
                if (self.sectionSelectedImages) {
                    UIImage *highlightIcon = [self.sectionSelectedImages objectAtIndex:idx];
                    imageLayer.contents = (id)highlightIcon.CGImage;
                } else {
                    imageLayer.contents = (id)icon.CGImage;
                }
				titleLayer.foregroundColor = self.selectedTextColor.CGColor;
            } else {
                imageLayer.contents = (id)icon.CGImage;
				titleLayer.foregroundColor = self.textColor.CGColor;
            }
            
            [self.scrollView.layer addSublayer:imageLayer];
			titleLayer.contentsScale = [[UIScreen mainScreen] scale];
            [self.scrollView.layer addSublayer:titleLayer];
			
        }];
	}
    
    CALayer* shadow = [CALayer layer];
    shadow.backgroundColor = [UIColor colorWithRed:200/255. green:199/255. blue:204/255. alpha:1].CGColor;
    shadow.frame = CGRectMake(0, self.frame.size.height - 1, self.frame.size.width, 1);
    [self.scrollView.layer addSublayer:shadow];
    
    // Add the selection indicators
    if (self.selectedSegmentIndex != NovaSegmentedControlNoSegment) {
        if (self.selectionStyle == NovaSegmentedControlSelectionStyleArrow) {
            if (!self.selectionIndicatorArrowLayer.superlayer) {
                [self setArrowFrame];
                [self.scrollView.layer addSublayer:self.selectionIndicatorArrowLayer];
            }
        } else {
            if (!self.selectionIndicatorStripLayer.superlayer) {
                self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
                [self.scrollView.layer addSublayer:self.selectionIndicatorStripLayer];
                
                if (self.selectionStyle == NovaSegmentedControlSelectionStyleBox && !self.selectionIndicatorBoxLayer.superlayer) {
                    self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];

                    [self.scrollView.layer insertSublayer:self.selectionIndicatorBoxLayer atIndex:0];
                }
            }
        }
    }
}

- (void)setArrowFrame {
    self.selectionIndicatorArrowLayer.frame = [self frameForSelectionIndicator];
    
    self.selectionIndicatorArrowLayer.mask = nil;

    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    
    CGPoint p1 = CGPointZero;
    CGPoint p2 = CGPointZero;
    CGPoint p3 = CGPointZero;
    
    if (self.selectionIndicatorLocation == NovaSegmentedControlSelectionIndicatorLocationDown) {
        p1 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.width / 2, 0);
        p2 = CGPointMake(0, self.selectionIndicatorArrowLayer.bounds.size.height);
        p3 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.width , self.selectionIndicatorArrowLayer.bounds.size.height);
    }
    
    if (self.selectionIndicatorLocation == NovaSegmentedControlSelectionIndicatorLocationUp) {
        p1 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.width / 2, self.selectionIndicatorArrowLayer.bounds.size.height);
        p2 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.width, 0);
        p3 = CGPointMake(0, 0);
    }

    [arrowPath moveToPoint:p2];
    [arrowPath addLineToPoint:p1];
    [arrowPath addLineToPoint:p3];
    
    self.selectionIndicatorArrowShapeLayer.path = arrowPath.CGPath;
    self.selectionIndicatorArrowShapeLayer.strokeColor = self.selectionIndicatorColor.CGColor;
    self.selectionIndicatorArrowShapeLayer.lineWidth = 1.f;
    self.selectionIndicatorArrowShapeLayer.fillColor = nil;
    
    
    /*
    [arrowPath moveToPoint:p1];
    [arrowPath addLineToPoint:p2];
    [arrowPath addLineToPoint:p3];
    [arrowPath closePath];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.selectionIndicatorArrowLayer.bounds;
    maskLayer.path = arrowPath.CGPath;
    maskLayer.backgroundColor = self.selectionIndicatorColor.CGColor;
    self.selectionIndicatorArrowLayer.mask = maskLayer;*/
}

- (CGRect)frameForSelectionIndicator:(NSInteger)selectedIndex
{
    CGFloat indicatorYOffset = 0.0f;
    
    if (self.selectionIndicatorLocation == NovaSegmentedControlSelectionIndicatorLocationDown) {
        indicatorYOffset = self.bounds.size.height - self.selectionIndicatorHeight;
    }
    
    CGFloat sectionWidth = 0.0f;
    CGFloat sectionWidthAddtion = 10.f;
    if (self.type == NovaSegmentedControlTypeText) {
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
        CGFloat stringWidth = ceilf([[self.sectionTitles objectAtIndex:selectedIndex] sizeWithAttributes:@{NSFontAttributeName: self.font}].width);
#else
        CGFloat stringWidth = roundf([[self.sectionTitles objectAtIndex:selectedIndex] sizeWithFont:self.font].width);
#endif

        sectionWidth = stringWidth + sectionWidthAddtion;
    } else if (self.type == NovaSegmentedControlTypeImages) {
        UIImage *sectionImage = [self.sectionImages objectAtIndex:selectedIndex];
        CGFloat imageWidth = sectionImage.size.width;
        sectionWidth = imageWidth;
    } else if (self.type == NovaSegmentedControlTypeTextImages) {
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
        CGFloat stringWidth = ceilf([[self.sectionTitles objectAtIndex:selectedIndex] sizeWithAttributes:@{NSFontAttributeName: self.font}].width);
#else
        CGFloat stringWidth = roundf([[self.sectionTitles objectAtIndex:selectedIndex] sizeWithFont:self.font].width);
#endif
		UIImage *sectionImage = [self.sectionImages objectAtIndex:selectedIndex];
		CGFloat imageWidth = sectionImage.size.width;
        if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleFixed) {
            sectionWidth = MAX(stringWidth, imageWidth);
        } else if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleDynamic) {
            sectionWidth = imageWidth + segmentImageTextPadding + stringWidth;
        }
	}
    
    if (self.selectionStyle == NovaSegmentedControlSelectionStyleArrow) {
        CGFloat widthToEndOfSelectedSegment = (self.segmentWidth * selectedIndex) + self.segmentWidth;
        CGFloat widthToStartOfSelectedIndex = (self.segmentWidth * selectedIndex);
        
        CGFloat x = widthToStartOfSelectedIndex + ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) - (self.selectionIndicatorHeight);
        return CGRectMake(x, indicatorYOffset, self.selectionIndicatorHeight * 2, self.selectionIndicatorHeight);
    } else {
        if (self.selectionStyle == NovaSegmentedControlSelectionStyleTextWidthStripe &&
            sectionWidth <= self.segmentWidth &&
            self.segmentWidthStyle != NovaSegmentedControlSegmentWidthStyleDynamic) {
            CGFloat widthToEndOfSelectedSegment = (self.segmentWidth * selectedIndex) + self.segmentWidth;
            CGFloat widthToStartOfSelectedIndex = (self.segmentWidth * selectedIndex);
            
            CGFloat x = ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) + (widthToStartOfSelectedIndex - sectionWidth / 2);
            return CGRectMake(x, indicatorYOffset, sectionWidth, self.selectionIndicatorHeight);
        } else {
            if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleDynamic) {
                CGFloat selectedSegmentOffset = 0.0f;
                
                NSInteger i = 0;
                for (NSNumber *width in self.segmentWidthsArray) {
                    if (selectedIndex == i)
                        break;
                    selectedSegmentOffset = selectedSegmentOffset + [width floatValue];
                    i++;
                }
                
                return CGRectMake(selectedSegmentOffset, indicatorYOffset, [[self.segmentWidthsArray objectAtIndex:selectedIndex] floatValue], self.selectionIndicatorHeight);
            }
            
            return CGRectMake(self.segmentWidth * selectedIndex, indicatorYOffset, self.segmentWidth, self.selectionIndicatorHeight);
        }
    }

}

- (CGRect)frameForSelectionIndicator {
    return [self frameForSelectionIndicator:self.selectedSegmentIndex];
}

- (CGRect)frameForFillerSelectionIndicator
{
    return [self frameForFillerSelectionIndicator:self.selectedSegmentIndex];
}

- (CGRect)frameForFillerSelectionIndicator:(NSInteger)selectedIndex
{
    
    if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleDynamic) {
        CGFloat selectedSegmentOffset = 0.0f;
        
        NSInteger i = 0;
        for (NSNumber *width in self.segmentWidthsArray) {
            if (selectedIndex == i) {
                break;
            }
            selectedSegmentOffset = selectedSegmentOffset + [width floatValue];
            
            i++;
        }
        
        return CGRectMake(selectedSegmentOffset, 0, [[self.segmentWidthsArray objectAtIndex:selectedIndex] floatValue], CGRectGetHeight(self.frame));
    }
    CGRect rect = CGRectMake(self.segmentWidth * selectedIndex, 0, self.segmentWidth, CGRectGetHeight(self.frame));
    
    CGFloat zoomedWidth = rect.size.width * 0.782;
    CGFloat zoomedHeight = rect.size.height * 0.625;
    CGPoint center = CGPointMake(rect.origin.x + rect.size.width/2., rect.origin.y + rect.size.height / 2.);
    return CGRectMake(center.x - zoomedWidth / 2.f, center.y - zoomedHeight / 2.f, zoomedWidth, zoomedHeight  );
}



- (void)updateSegmentsRects {
    self.scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    
    // When `scrollEnabled` is set to YES, segment width will be automatically set to the width of the biggest segment's text or image,
    // otherwise it will be equal to the width of the control's frame divided by the number of segments.
    if ([self sectionCount] > 0) {
        self.segmentWidth = self.frame.size.width / [self sectionCount];
    }
    
    if (self.type == NovaSegmentedControlTypeText && self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleFixed) {
        for (NSString *titleString in self.sectionTitles) {
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
            CGFloat stringWidth = ceilf([titleString sizeWithAttributes:@{NSFontAttributeName:self.font}].width) + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
#else
            CGFloat stringWidth = roundf([titleString sizeWithFont:self.font].width) + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
#endif
            self.segmentWidth = MAX(stringWidth, self.segmentWidth);
        }
    } else if (self.type == NovaSegmentedControlTypeText && self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleDynamic) {
        NSMutableArray *mutableSegmentWidths = [NSMutableArray array];
        
        for (NSString *titleString in self.sectionTitles) {
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
            CGFloat stringWidth = ceilf([titleString sizeWithAttributes:@{NSFontAttributeName: self.font}].width) + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
#else
            CGFloat stringWidth = roundf([titleString sizeWithFont:self.font].width) + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
#endif
            [mutableSegmentWidths addObject:[NSNumber numberWithFloat:stringWidth]];
        }
        self.segmentWidthsArray = [mutableSegmentWidths copy];
    } else if (self.type == NovaSegmentedControlTypeImages) {
        for (UIImage *sectionImage in self.sectionImages) {
            CGFloat imageWidth = sectionImage.size.width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            self.segmentWidth = MAX(imageWidth, self.segmentWidth);
        }
    } else if (self.type == NovaSegmentedControlTypeTextImages && self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleFixed){
        //lets just use the title.. we will assume it is wider then images...
        for (NSString *titleString in self.sectionTitles) {
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
            CGFloat stringWidth = ceilf([titleString sizeWithAttributes:@{NSFontAttributeName: self.font}].width) + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
#else
            CGFloat stringWidth = roundf([titleString sizeWithFont:self.font].width) + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
#endif
            self.segmentWidth = MAX(stringWidth, self.segmentWidth);
        }
    } else if (self.type == NovaSegmentedControlTypeTextImages && NovaSegmentedControlSegmentWidthStyleDynamic) {
        NSMutableArray *mutableSegmentWidths = [NSMutableArray array];
        
        int i = 0;
        for (NSString *titleString in self.sectionTitles) {
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
            CGFloat stringWidth = ceilf([titleString sizeWithAttributes:@{NSFontAttributeName: self.font}].width) + self.segmentEdgeInset.right;
#else
            CGFloat stringWidth = roundf([titleString sizeWithFont:self.font].width) + self.segmentEdgeInset.right;
#endif
            UIImage *sectionImage = [self.sectionImages objectAtIndex:i];
            CGFloat imageWidth = sectionImage.size.width + self.segmentEdgeInset.left;
            
            CGFloat combinedWidth = imageWidth + segmentImageTextPadding + stringWidth;
            
            [mutableSegmentWidths addObject:[NSNumber numberWithFloat:combinedWidth]];
            
            i++;
        }
        self.segmentWidthsArray = [mutableSegmentWidths copy];
    }
    
    self.scrollView.scrollEnabled = self.isUserDraggable;
    self.scrollView.contentSize = CGSizeMake([self totalSegmentedControlWidth], self.frame.size.height);
}

- (NSUInteger)sectionCount {
    if (self.type == NovaSegmentedControlTypeText) {
        return self.sectionTitles.count;
    } else if (self.type == NovaSegmentedControlTypeImages ||
               self.type == NovaSegmentedControlTypeTextImages) {
        return self.sectionImages.count;
    }
    
    return 0;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    // Control is being removed
    if (newSuperview == nil)
        return;
    
    if (self.sectionTitles || self.sectionImages) {
        [self updateSegmentsRects];
    }
}

#pragma mark - Touch
-(CALayer*) currentLayer
{
    switch (self.selectionStyle)
    {
        case NovaSegmentedControlSelectionStyleTextWidthStripe:
        case NovaSegmentedControlSelectionStyleFullWidthStripe:
            return self.selectionIndicatorStripLayer;
            break;
        case NovaSegmentedControlSelectionStyleBox:
            return self.selectionIndicatorBoxLayer;
            break;
        case NovaSegmentedControlSelectionStyleArrow:
            return self.selectionIndicatorArrowLayer;
            break;
        default:
            return self.selectionIndicatorStripLayer;
            break;
    }
    
}

-(CGRect) frameForCurrentLayer:(NSInteger)index;
{
    switch (self.selectionStyle)
    {
        case NovaSegmentedControlSelectionStyleTextWidthStripe:
        case NovaSegmentedControlSelectionStyleFullWidthStripe:
        case NovaSegmentedControlSelectionStyleArrow:
            return [self frameForSelectionIndicator:index];
            break;
        case NovaSegmentedControlSelectionStyleBox:
            return [self frameForFillerSelectionIndicator:index];
            break;
        default:
            return [self frameForSelectionIndicator:index];
            break;
    }
}

-(CGFloat) floatFrom:(CGFloat)fromValue to:(CGFloat)toValue percent:(CGFloat)percent
{
    if (fromValue < toValue)
    {
        return fromValue + (toValue - fromValue) * percent;
    }
    else
    {
        return toValue + (fromValue - toValue) * percent;
    }
    
}

-(UIColor*) colorBetweenFrom:(UIColor*)fromColor to:(UIColor*)toColor percent:(CGFloat)percent
{
    
    const CGFloat* from = CGColorGetComponents(fromColor.CGColor);
    const CGFloat* to = CGColorGetComponents(toColor.CGColor);
    
    CGFloat red = [self floatFrom:from[0] to:to[0] percent:percent];
    CGFloat green = [self floatFrom:from[1] to:to[1] percent:percent];
    CGFloat blue = [self floatFrom:from[2] to:to[2] percent:percent];
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
}



-(void) beginDragging:(NSInteger)index
{
    if (self.isDraggingBegin)
    {
        return;
    }
    
    self.isDraggingBegin = YES;
    self.draggingStartOffset = self.currentLayer.position.x;
    //NSLog(@"Segment: begin dragging");
}



-(void) dragging:(CGFloat)percent
{
    if (self.isDraggingBegin == NO || percent == 0)
    {
        return;
    }
   
    
    CGPoint moveToPosition;
    if (percent < 0)
    {
        if (self.selectedSegmentIndex == 0)
        {
            return;
        }
        CGRect previous = [self frameForCurrentLayer:(self.selectedSegmentIndex - 1)];
        CGFloat total = self.draggingStartOffset - previous.origin.x;
        moveToPosition = CGPointMake(self.draggingStartOffset + total * percent, self.currentLayer.position.y);
        
        CATextLayer* previousLayer = [self.textLayers objectAtIndex:(self.selectedSegmentIndex - 1)];
        CATextLayer* currentTextLayer = [self.textLayers objectAtIndex:self.selectedSegmentIndex];
        previousLayer.foregroundColor = [self colorBetweenFrom:self.textColor to:self.selectedTextColor percent:percent].CGColor;
        currentTextLayer.foregroundColor = [self colorBetweenFrom:self.selectedTextColor to:self.textColor percent:percent].CGColor;
    }
    else
    {
        if (self.selectedSegmentIndex == ([self sectionCount]-1) )
        {
            return;
        }
        CGRect next = [self frameForCurrentLayer:(self.selectedSegmentIndex + 1)];
        CGFloat total = next.origin.x - self.draggingStartOffset;
        moveToPosition = CGPointMake(self.draggingStartOffset + total * percent, self.currentLayer.position.y);
        
        CATextLayer* nextLayer = [self.textLayers objectAtIndex:(self.selectedSegmentIndex + 1)];
        CATextLayer* currentTextLayer = [self.textLayers objectAtIndex:self.selectedSegmentIndex];
        nextLayer.foregroundColor = [self colorBetweenFrom:self.textColor to:self.selectedTextColor percent:percent].CGColor;
        currentTextLayer.foregroundColor = [self colorBetweenFrom:self.selectedTextColor to:self.textColor percent:percent].CGColor;

    }
    self.currentLayer.position = moveToPosition;
    //NSLog(@"Segment: dragging to %f, %f", moveToPosition.x, moveToPosition.y);
}

-(void) endDragging:(NSInteger)index
{
    if (self.isDraggingBegin == NO)
    {
        return;
    }
    
    self.isDraggingBegin = NO;
    //NSLog(@"Segment: end dragging: %d", index);
    
    if (index == self.selectedSegmentIndex) // Canceled
    {
        [self setSelectedSegmentIndex:self.selectedSegmentIndex animated:YES notify:NO];
    }
    else
    {
        self.selectedSegmentIndex = index;
        [self setSelectedSegmentIndex:self.selectedSegmentIndex animated:YES notify:NO];
    }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    
    if (CGRectContainsPoint(self.bounds, touchLocation)) {
        NSInteger segment = 0;
        if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleFixed) {
            segment = (touchLocation.x + self.scrollView.contentOffset.x) / self.segmentWidth;
        } else if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleDynamic) {
            // To know which segment the user touched, we need to loop over the widths and substract it from the x position.
            CGFloat widthLeft = (touchLocation.x + self.scrollView.contentOffset.x);
            for (NSNumber *width in self.segmentWidthsArray) {
                widthLeft = widthLeft - [width floatValue];
                
                // When we don't have any width left to substract, we have the segment index.
                if (widthLeft <= 0)
                    break;
                
                segment++;
            }
        }
        
        if (segment != self.selectedSegmentIndex && segment < [self.sectionTitles count]) {
            // Check if we have to do anything with the touch event
            if (self.isTouchEnabled)
                [self setSelectedSegmentIndex:segment animated:self.shouldAnimateUserSelection notify:YES];
        }
    }
}

#pragma mark - Scrolling

- (CGFloat)totalSegmentedControlWidth {
    if (self.type == NovaSegmentedControlTypeText && self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleFixed) {
        return self.sectionTitles.count * self.segmentWidth;
    } else if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleDynamic) {
        return [[self.segmentWidthsArray valueForKeyPath:@"@sum.self"] floatValue];
    } else {
        return self.sectionImages.count * self.segmentWidth;
    }
}

- (void)scrollToSelectedSegmentIndex {
    CGRect rectForSelectedIndex;
    CGFloat selectedSegmentOffset = 0;
    if (self.segmentWidthStyle == NovaSegmentedControlSegmentWidthStyleFixed) {
        rectForSelectedIndex = CGRectMake(self.segmentWidth * self.selectedSegmentIndex,
                                          0,
                                          self.segmentWidth,
                                          self.frame.size.height);
        
        selectedSegmentOffset = (CGRectGetWidth(self.frame) / 2) - (self.segmentWidth / 2);
    } else {
        NSInteger i = 0;
        CGFloat offsetter = 0;
        for (NSNumber *width in self.segmentWidthsArray) {
            if (self.selectedSegmentIndex == i)
                break;
            offsetter = offsetter + [width floatValue];
            i++;
        }
        
        rectForSelectedIndex = CGRectMake(offsetter,
                                          0,
                                          [[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue],
                                          self.frame.size.height);
        
        selectedSegmentOffset = (CGRectGetWidth(self.frame) / 2) - ([[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue] / 2);
    }
    
    
    CGRect rectToScrollTo = rectForSelectedIndex;
    rectToScrollTo.origin.x -= selectedSegmentOffset;
    rectToScrollTo.size.width += selectedSegmentOffset * 2;
    [self.scrollView scrollRectToVisible:rectToScrollTo animated:YES];
}

#pragma mark - Index change

- (void)setSelectedSegmentIndex:(NSInteger)index {
    [self setSelectedSegmentIndex:index animated:NO notify:NO];
}

- (void)setSelectedSegmentIndex:(NSUInteger)index animated:(BOOL)animated {
    [self setSelectedSegmentIndex:index animated:animated notify:NO];
}

-(CGPoint) centerOfRect:(CGRect)rect
{
    return CGPointMake(rect.origin.x + (rect.size.width / 2.), rect.origin.y + (rect.size.height / 2.) );
}

- (void)animateIndicator
{
   
//    if (0)
//    {
//        [self.selectionIndicatorStripLayer pop_removeAllAnimations];
//        POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
//        CGPoint position = [self centerOfRect:self.selectionIndicatorStripLayer.frame];
//        animation.fromValue = [NSValue valueWithCGPoint:position];
//        animation.velocity = [NSValue valueWithCGPoint:position];
//        CGPoint destPosition = [self centerOfRect:[self frameForSelectionIndicator]];
//        animation.toValue = [NSValue valueWithCGPoint:destPosition];
//        animation.springSpeed = 20;
//        animation.springBounciness = 10;
//        animation.name = @"indicator";
//        POPAnimationTracer *tracer = animation.tracer;
//        tracer.shouldLogAndResetOnCompletion = YES;
//        [tracer start];
//        
//        [self.selectionIndicatorStripLayer pop_addAnimation:animation forKey:@"animation"];
//        self.animation = animation;
//    }
//    else
//    {
    // Animate to new position
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.15f];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [self setArrowFrame];
    self.selectionIndicatorArrowLayer.frame = [self frameForSelectionIndicator];
    self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
    self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
    [CATransaction commit];
    //}
}

- (void)setSelectedSegmentIndex:(NSUInteger)index animated:(BOOL)animated notify:(BOOL)notify {
    _selectedSegmentIndex = index;
    [self setNeedsDisplay];
    
    if (index == NovaSegmentedControlNoSegment) {
        [self.selectionIndicatorArrowLayer removeFromSuperlayer];
        [self.selectionIndicatorStripLayer removeFromSuperlayer];
        [self.selectionIndicatorBoxLayer removeFromSuperlayer];
    } else {
        [self scrollToSelectedSegmentIndex];
        
        if (animated) {
            // If the selected segment layer is not added to the super layer, that means no
            // index is currently selected, so add the layer then move it to the new
            // segment index without animating.
            if(self.selectionStyle == NovaSegmentedControlSelectionStyleArrow) {
                if ([self.selectionIndicatorArrowLayer superlayer] == nil) {
                    [self.scrollView.layer addSublayer:self.selectionIndicatorArrowLayer];
                    
                    [self setSelectedSegmentIndex:index animated:NO notify:YES];
                    return;
                }
            }else {
                if ([self.selectionIndicatorStripLayer superlayer] == nil) {
                    [self.scrollView.layer addSublayer:self.selectionIndicatorStripLayer];
                    
                    if (self.selectionStyle == NovaSegmentedControlSelectionStyleBox && [self.selectionIndicatorBoxLayer superlayer] == nil)
                        [self.scrollView.layer insertSublayer:self.selectionIndicatorBoxLayer atIndex:0];
                    
                    [self setSelectedSegmentIndex:index animated:NO notify:YES];
                    return;
                }
            }
            
            if (notify)
                [self notifyForSegmentChangeToIndex:index];
            
            // Restore CALayer animations
            self.selectionIndicatorArrowLayer.actions = nil;
            self.selectionIndicatorStripLayer.actions = nil;
            self.selectionIndicatorBoxLayer.actions = nil;
            
            [self animateIndicator];
        } else {
            // Disable CALayer animations
            NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"position", [NSNull null], @"bounds", nil];
            self.selectionIndicatorArrowLayer.actions = newActions;
            [self setArrowFrame];
            
            self.selectionIndicatorStripLayer.actions = newActions;
            self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
            
            self.selectionIndicatorBoxLayer.actions = newActions;
            self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
            
            if (notify)
                [self notifyForSegmentChangeToIndex:index];
        }
    }
}

- (void)notifyForSegmentChangeToIndex:(NSInteger)index {
    if (self.superview)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    if (self.indexChangeBlock)
        self.indexChangeBlock(index);
}

@end
