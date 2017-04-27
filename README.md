# PHImageManager-GetPhotos

Because the AssetsLibrary is deprecated after iOS 9.0, Apple use Photos framework instead of it. 

## Usage

```get full screen image
[[SEPhotoUtility shareInstance] fullScreenImageFromAsset:asset resultHandler:^(UIImage *result, NSDictionary *info) {
[scrollView configViewWithImage:result thumbnail:[SEImageCache placeHolderImage] needBlur:NO];
}];
```

```Save selected images to your project library directory
NSArray* results = [[SEPhotoUtility shareInstance] saveOriginalImagesFromCollection:self.currentCollection atIndexs:self.imagePicker.selectedImageIndexes options:self.imagePicker.dictImageFullFlags spec:self.spec];
```

```Save selected images to your project library directory
NSArray* results = [[SEPhotoUtility shareInstance] saveOriginalImagesFromCollection:self.currentCollection atIndexs:self.imagePicker.selectedImageIndexes options:self.imagePicker.dictImageFullFlags spec:self.spec];
```

```Get thumbnail image with PHAsset object  synchronously
    UIImage *thumbnailImage = [[SEPhotoUtility shareInstance] thumbnailImageFromAsset:asset];
```
```Get thumbnail image with PHAsset object asynchronously
[[SEPhotoUtility shareInstance] thumbnailImageFromAsset:asset resultHandler:^(UIImage *result, NSDictionary *info) {
    self.imageView.image = result;
}];
```

## License

The MIT License

Copyright <YEAR> <COPYRIGHT HOLDER>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
