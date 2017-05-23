//
//  SQImagePicker.m
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import "SQImagePicker.h"

#define FULL_QUALITY 0.75f

@implementation SQImagePicker

-(id) init
{
    return [self initWithMaxSelectImage:0];
}

-(id) initWithMaxSelectImage:(NSInteger)max
{
    self = [super init];
    if (self)
    {
        self.selectedImageIndexes = [NSMutableArray array];
        self.dictImageFullFlags = [NSMutableDictionary dictionary];
        self.maxSelectImage = max;
        self.totalSelected = 0;
    }
    
    return self;
}

+(id) imagePickerWithMaxSelectImage:(NSInteger)max
{
    return [[SQImagePicker alloc] initWithMaxSelectImage:max];
}

-(BOOL) isSelectedAtIndex:(NSInteger)index
{
    if ([self.selectedImageIndexes containsObject:@(index)])
    {
        return YES;
    }
    
    return NO;
}

-(BOOL) toggleSelectImageAtIndex:(NSInteger)index maxReached:(BOOL*)maxReached
{
    BOOL isSelect = ![self isSelectedAtIndex:index];
    *maxReached = NO;
    
    if (isSelect)
    {
        if (self.maxSelectImage > 0 && (self.totalSelected + 1) > self.maxSelectImage)
        {
            *maxReached = YES;
            return NO;
        }
        
        self.totalSelected ++;
        [self.selectedImageIndexes addObject:@(index)];
    }
    else
    {
        self.totalSelected --;
        [self.selectedImageIndexes removeObject:@(index)];
    }
    return isSelect;
}

-(BOOL) isNotFullImageAtIndex:(NSInteger)index
{
    if (self.dictImageFullFlags[@(index)])
    {
        return NO;
    }
    
    return YES;
}

-(BOOL) toogleFullImageAtIndex:(NSInteger)index
{
    BOOL isNotFull = ![self isNotFullImageAtIndex:index];
    if (!isNotFull)
    {
        [self.dictImageFullFlags setObject:@(FULL_QUALITY) forKey:@(index)];
    }
    else
    {
        [self.dictImageFullFlags removeObjectForKey:@(index)];
    }
    
    return isNotFull;
}

@end
