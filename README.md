# SQPhotoUtility

Because the AssetsLibrary is deprecated after iOS 9.0, Apple use Photos framework instead of it. 

## Usage
+(SQPhotoUtility *)shareInstance;

/**
Get image count of PHAssetCollection
 
 @param collection the collection who is being used.
 @return count of image.
 */
-(NSInteger)imageCountOfCollection:(PHAssetCollection *)collection;

```get full screen image
[[SQPhotoUtility shareInstance] imageCountOfCollection:collection];
}];
```

/**
 Get the poster image of PHAssectCollection synchronously

 @param collection collection the collection who is being used
 @return a thumbnail image default size is {50, 50}
 */
-(UIImage*) postImageFromCollection:(PHAssetCollection *)collection;

```get collection poster image
[[SQPhotoUtility shareInstance] postImageFromCollection:collection];
}];
```

/**
Get the thumbnail image of PHAsset synchronously

@param asset the asset you want to get image from
@return a thumbnail image default size is {50, 50}
*/
-(UIImage *) thumbnailImageFromAsset:(PHAsset *)asset;

```Get thumbnail image with PHAsset object  synchronously
    UIImage *thumbnailImage = [[SQPhotoUtility shareInstance] thumbnailImageFromAsset:asset];
```

/**
Get the thumbnail image of PHAsset asynchronously

@param asset the asset you want to get image from
@param resultHandler completion block when finished get the image .
*/
-(void) thumbnailImageFromAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage * result, NSDictionary * info))resultHandler;

```Get thumbnail image with PHAsset object asynchronously
[[SQPhotoUtility shareInstance] thumbnailImageFromAsset:asset resultHandler:^(UIImage *result, NSDictionary *info) {
    self.imageView.image = result;
}];
```

/**
 Get the full screen image of PHAsset asynchronously
 
 @param asset the asset you want to get image from
 @param resultHandler completion block when finished get the image .
 */
-(void) fullScreenImageFromAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage * result, NSDictionary * info))resultHandler;

/**
If you selected some images in a collection, save them to the project's library directory

 @param collection collection the collection which you selected image from
 @param indexes completion block when finished get the image .
 @param path where the image would be saved.
*/
-(NSArray*) saveOriginalImagesFromCollection:(PHAssetCollection *)collection atIndexes:(NSArray*)indexes directoryPath:(NSString *)path;

/**
 Asset image file size.
 
 @param asset the asset you want to get file size
 @param resultHandler completion block give the file size infomation.
 
 */
-(void)fileSizeWithAsset:(PHAsset *)asset resultHandler:(void (^)(long long fileSize))resultHandler;

## License

The MIT License

Copyright <YEAR> <COPYRIGHT HOLDER>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
