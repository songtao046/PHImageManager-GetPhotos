//
//  PHImageManager+GetPhotos.h
//  SEPhotoUtility
//
//  Created by Ma SongTao on 26/04/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface PHImageManager (GetPhotos)

-(NSInteger)imageCountOfCollection:(PHAssetCollection *)collection;

-(UIImage*) postImageOfCollection:(PHAssetCollection *)collection;


//synchronous
-(UIImage *) thumbnailImageFromAsset:(PHAsset *)asset;

//synchronous
-(void) thumbnailImageFromAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage * result, NSDictionary * info))resultHandler;
-(void) fullScreenImageFromAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage * result, NSDictionary * info))resultHandler;


-(NSArray*) saveOriginalImagesFromCollection:(PHAssetCollection *)collection atIndexs:(NSArray*)indexs options:(NSDictionary*)options;

// Thumbnail
-(void) saveThumbnailFromData:(NSData*)data metaData:(NSDictionary*)metaData fileName:(NSString*)fileName;


-(void)fileSizeWithAsset:(PHAsset *)asset resultHandler:(void (^)(long long fileSize))resultHandler;

@end
