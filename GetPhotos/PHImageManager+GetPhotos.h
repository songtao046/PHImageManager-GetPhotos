//
//  PHImageManager+GetPhotos.h
//  SEPhotoUtility
//
//  Created by Squirrel on 26/04/2017.
//  Copyright © 2017 songtao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface PHImageManager (GetPhotos)

/**
 Get image count of PHAssetCollection
 
 @param collection the collection who is being used.
 @return count of image.
 */
-(NSInteger)imageCountOfCollection:(PHAssetCollection *)collection;


/**
 Get the poster image of PHAssectCollection synchronously
 
 @param collection collection the collection who is being used
 @return a thumbnail image default size is {50, 50}
 */
-(UIImage*) postImageOfCollection:(PHAssetCollection *)collection;


/**
 Get the thumbnail image of PHAsset synchronously
 
 @param asset the asset you want to get image from
 @return a thumbnail image default size is {50, 50}
 */
-(UIImage *) thumbnailImageFromAsset:(PHAsset *)asset;

/**
 Get the thumbnail image of PHAsset asynchronously
 
 @param asset the asset you want to get image from
 @param resultHandler completion block when finished get the image .
 */
-(void) thumbnailImageFromAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage * result, NSDictionary * info))resultHandler;

/**
 Get the thumbnail image of PHAsset asynchronously
 
 @param asset the asset you want to get image from
 @param resultHandler completion block when finished get the image .
 */
-(void) fullScreenImageFromAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage * result, NSDictionary * info))resultHandler;


/**
 If you selected some images in a collection, save them to the project's library directory
 
 @param collection collection the collection which you selected image from
 @param indexes completion block when finished get the image .
 */
-(NSArray*) saveOriginalImagesFromCollection:(PHAssetCollection *)collection atIndexes:(NSArray*)indexes;


/**
If save image data to NSSearchPathForDirectoriesInDomains();

@param data image data
 @param metaData image source properties, you can create it with CGImageSourceCopyPropertiesAtIndex, just like :
 (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(CGImageSourceRef, 0, NULL));
 @param fileName the file saved name.
*/

-(void) saveThumbnailFromData:(NSData*)data metaData:(NSDictionary*)metaData fileName:(NSString*)fileName;


/**
 Asset image file size.
 
 @param asset the asset you want to get file size
 @param resultHandler completion block give the file size infomation.
 
 */
-(void)fileSizeWithAsset:(PHAsset *)asset resultHandler:(void (^)(long long fileSize))resultHandler;

@end
