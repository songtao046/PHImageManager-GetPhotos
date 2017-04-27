//
//  PHImageManager+GetPhotos.m
//  SEPhotoUtility
//
//  Created by Squirrel on 26/04/2017.
//  Copyright © 2017 songtao. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.



#import "PHImageManager+GetPhotos.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define SCREEN_SCALE [UIScreen mainScreen].scale

@implementation PHImageManager (GetPhotos)

-(PHFetchOptions *)defaultFetchOptions
{
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    return fetchOptions;
}

-(NSInteger)imageCountOfCollection:(PHAssetCollection *)collection
{
    PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsInAssetCollection:collection options:self.defaultFetchOptions];
    return assetResult.count;
}

-(UIImage *)postImageOfCollection:(PHAssetCollection *)collection
{
    PHImageRequestOptions *imageOptions = [[PHImageRequestOptions alloc] init];
    imageOptions.synchronous = YES;
    PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsInAssetCollection:collection options:self.defaultFetchOptions];
    PHAsset *asset = [assetResult objectAtIndex:0];
    
    __block UIImage *image = nil;
    [self requestImageForAsset:asset targetSize:CGSizeMake(30 * SCREEN_SCALE, 30 * SCREEN_SCALE) contentMode:PHImageContentModeAspectFill options:imageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
        if (downloadFinined) {
            image = result;
        }
    }];
    return image;
}

-(void) thumbnailImageFromAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage *__nullable result, NSDictionary *__nullable info))resultHandler
{
    CGFloat edgeLength = ([UIScreen mainScreen].bounds.size.width - 10)/4.0f;
    CGSize targetSize = CGSizeMake(edgeLength * SCREEN_SCALE, edgeLength * SCREEN_SCALE);
    // 请求图片
    [self requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
        if (downloadFinined) {
            resultHandler(result, info);
        }
    }];
}

-(void) fullScreenImageFromAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage *__nullable result, NSDictionary *__nullable info))resultHandler
{
    CGSize targetSize = CGSizeMake(MIN(asset.pixelWidth, [UIScreen mainScreen].bounds.size.width), MIN(asset.pixelWidth, [UIScreen mainScreen].bounds.size.height));
    // 请求图片
    [self requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
        if (downloadFinined) {
            resultHandler(result, info);
        }
    }];
}

-(UIImage *) thumbnailImageFromAsset:(PHAsset *)asset
{
    PHImageRequestOptions *imageOptions = [[PHImageRequestOptions alloc] init];
    imageOptions.synchronous = YES;
    CGFloat edgeLength = ([UIScreen mainScreen].bounds.size.width - 10)/4.0f;
    CGSize targetSize = CGSizeMake(edgeLength * SCREEN_SCALE, edgeLength * SCREEN_SCALE);
    // 请求图片
    __block UIImage *image = nil;
    [self requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:imageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
        if (downloadFinined) {
            image = result;
        }
    }];
    return image;
}



-(NSArray*) saveOriginalImagesFromCollection:(PHAssetCollection *)collection atIndexes:(NSArray*)indexes
{
    if (collection == nil) return nil;
    
    __block NSMutableDictionary* results = [NSMutableDictionary dictionary];
    NSMutableArray *resultsArray = [NSMutableArray array];
    
    NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
    for (NSNumber* index in indexes)
    {
        [indexSet addIndex:[index integerValue]];
        //Generate file name
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        NSString* uuidStr = [NSString stringWithString:(__bridge NSString *)string];
        CFRelease(string);
        NSString* fileName = uuidStr;
        
        [results setObject:fileName forKey:index];
        [resultsArray addObject:fileName];
    }
    
    // 采取同步获取图片（只获得一次图片）
    PHImageRequestOptions *imageOptions = [[PHImageRequestOptions alloc] init];
    imageOptions.synchronous = YES;
    imageOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    // 遍历这个相册中的所有图片
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions];
    
    for (NSNumber *index in indexes)
    {
        PHAsset *asset = [assetResult objectAtIndex:[index integerValue]];
        
        [self requestImageDataForAsset:asset options:imageOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData,
                                                                       NULL);
            // Make sure the image source exists before continuing.
            if (imageSource == NULL){
                fprintf(stderr, "Image source is NULL.");
                return;
            }
            NSDictionary* metadata = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL));
            
            [self saveThumbnailFromData:imageData metaData:metadata fileName:[results objectForKey:index]];
        }];
    }
    return resultsArray;
}

// Thumbnail
-(void) saveThumbnailFromData:(NSData*)data metaData:(NSDictionary*)metaData fileName:(NSString*)fileName
{
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    // Make sure the image source exists before continuing.
    
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0,
                                                              (__bridge CFDictionaryRef)
                                                              @{
                                                                (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                                (NSString *)kCGImageSourceThumbnailMaxPixelSize : [NSNumber numberWithUnsignedLong:100],
                                                                (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                                }
                                                              );
    CFRelease(source);
    if (!imageRef)
    {
        return;
    }
    NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[libraryPaths objectAtIndex:0] stringByAppendingPathComponent:fileName];
    
    
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:filePath];
    CFMutableDictionaryRef mSaveMetaAndOpts = CFDictionaryCreateMutable(nil, 0,&kCFTypeDictionaryKeyCallBacks,  &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(mSaveMetaAndOpts, kCGImageDestinationLossyCompressionQuality,
                         (__bridge const void *)([NSNumber numberWithFloat:1]));
    if (metaData != nil)
    {
        for (NSString* key in [metaData allKeys])
        {
            CFDictionarySetValue(mSaveMetaAndOpts, (__bridge void*) key, (__bridge void*) metaData[key] );
        }
    }
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImage(destination, imageRef, mSaveMetaAndOpts);
    
    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    CFRelease(imageRef);
    
}

-(void)fileSizeWithAsset:(PHAsset *)asset resultHandler:(void (^)(long long fileSize))resultHandler
{
    PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
    [asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
        
        //        CIImage *fullImage = [CIImage imageWithContentsOfURL:contentEditingInput.fullSizeImageURL];
        //        NSLog(@"%@",contentEditingInput.fullSizeImageURL);//get url
        //        NSLog(@"%@", fullImage.properties.description);//get {TIFF}, {Exif}
        
        NSString *filePath = contentEditingInput.fullSizeImageURL.path;
        NSFileManager* manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:filePath]){
            long long fileSize = [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
            resultHandler(fileSize);
        }
        
    }];
}

@end
