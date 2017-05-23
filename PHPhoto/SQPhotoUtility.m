//
//  SQPhotoUtility.m
//  PHPhoto
//
//  Created by Ma SongTao on 23/05/2017.
//  Copyright © 2017 songtao. All rights reserved.
//
#import "SQPhotoUtility.h"
#import <CommonCrypto/CommonDigest.h> // For CC_MD5
#import <mach/mach.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#include <sys/xattr.h>

#import <sys/socket.h> // Per msqr
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>

#import <sys/utsname.h>

#define SCREEN_SCALE [UIScreen mainScreen].scale

static SQPhotoUtility *g_photoUtility;

@interface SQPhotoUtility()

@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) PHFetchOptions *commonFetchOptions;

@end

@implementation SQPhotoUtility

+(SQPhotoUtility *)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_photoUtility = [[SQPhotoUtility alloc] init];
        g_photoUtility.imageManager = [[PHCachingImageManager alloc] init];
        g_photoUtility.commonFetchOptions = [[PHFetchOptions alloc] init];
        g_photoUtility.commonFetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    });
    return g_photoUtility;
}

-(NSInteger)imageCountOfCollection:(PHAssetCollection *)collection
{
    PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsInAssetCollection:collection options:self.commonFetchOptions];
    return assetResult.count;
}

-(UIImage *)postImageFromCollection:(PHAssetCollection *)collection
{
    PHImageRequestOptions *imageOptions = [[PHImageRequestOptions alloc] init];
    imageOptions.synchronous = YES;
    PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsInAssetCollection:collection options:self.commonFetchOptions];
    PHAsset *asset = [assetResult objectAtIndex:0];
    
    __block UIImage *image = nil;
    [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(50 * SCREEN_SCALE, 50 * SCREEN_SCALE) contentMode:PHImageContentModeAspectFill options:imageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
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
    [self.imageManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
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
    [self.imageManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
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
    CGFloat edgeLength = 50;
    CGSize targetSize = CGSizeMake(edgeLength * SCREEN_SCALE, edgeLength * SCREEN_SCALE);
    // 请求图片
        __block UIImage *image = nil;
    [self.imageManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:imageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
        if (downloadFinined) {
            image = result;
        }
    }];
    return image;
}



-(NSArray*) saveOriginalImagesFromCollection:(PHAssetCollection *)collection atIndexes:(NSArray*)indexes directoryPath:(NSString *)path
{
    if (collection == nil) return nil;
    
    __block NSMutableDictionary* results = [NSMutableDictionary dictionary];
    NSMutableArray *resultsArray = [NSMutableArray array];
    
    NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
    for (NSNumber* index in indexes)
    {
        [indexSet addIndex:[index integerValue]];
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
        
        [self.imageManager requestImageDataForAsset:asset options:imageOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData,
                                                                       NULL);
            // Make sure the image source exists before continuing.
            if (imageSource == NULL){
                fprintf(stderr, "Image source is NULL.");
                return;
            }
            NSDictionary* metadata = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL));
            NSString *fileName = [results objectForKey:index];
            NSString* fullFilePath = [path stringByAppendingString:fileName];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            [self saveJPEGImage:image.CGImage jpegQuality:0.75 metaData:metadata toDisk:fullFilePath];
            [self saveThumbnailFromData:imageData maxPixelSize:MAX(image.size.width, image.size.height) metaData:metadata filePath:fullFilePath];
        }];
    }
    return resultsArray;
}

// Thumbnail
-(void) saveThumbnailFromData:(NSData*)data maxPixelSize:(NSUInteger)size metaData:(NSDictionary*)metaData filePath:(NSString*)filePath
{
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    // Make sure the image source exists before continuing.
    
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0,
                                                              (__bridge CFDictionaryRef)
                                                              @{
                                                                (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                                (NSString *)kCGImageSourceThumbnailMaxPixelSize : [NSNumber numberWithUnsignedLong:size],
                                                                (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                                }
                                                              );
    CFRelease(source);
    if (!imageRef)
    {
        return;
    }
    
    
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:filePath];
    CFMutableDictionaryRef mSaveMetaAndOpts = CFDictionaryCreateMutable(nil, 0,&kCFTypeDictionaryKeyCallBacks,  &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(mSaveMetaAndOpts, kCGImageDestinationLossyCompressionQuality,
                         (__bridge const void *)([NSNumber numberWithFloat:0.75]));
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


-(void) saveJPEGImage:(CGImageRef)imageRef jpegQuality:(CGFloat)quality metaData:(NSDictionary*)metaData toDisk:(NSString*)filePath
{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:filePath];
    CFMutableDictionaryRef mSaveMetaAndOpts = CFDictionaryCreateMutable(nil, 0,&kCFTypeDictionaryKeyCallBacks,  &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(mSaveMetaAndOpts, kCGImageDestinationLossyCompressionQuality,
                         (__bridge const void *)([NSNumber numberWithFloat:quality]));
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
