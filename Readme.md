## ASMediaFocusManager
ASMediaFocusManager gives the ability to focus on any image by a simple tap. The image is automatically animated to a focused fullscreen image view. Another tap on the focused view shrinks the image back to its initial position.

Works on iPhone and iPad.

![](Screenshots/video.gif) 

## Orientation
The focused view is automatically adapted to the screen orientation even if your main view controller is portrait only.

Because orientation management is different between iOS 5 and 6, this class is for iOS 6 only (although it should not be hard to adapt it to iOS 5).
## Use It
Copy the whole `ASMediaFocusManager` folder in your project.

* Create a ASMediaFocusManager
* Implement its delegate (ASMediaFocusDelegate)
* Declare all your views that you want to be focusable by calling `[ASMediaFocusManager installOnViews:]`

###Implementing
In your View Controller where some image views need focus feature, add this code.

```objc
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mediaFocusManager = [[ASMediaFocusManager alloc] init];
    self.mediaFocusManager.delegate = self;
    // Tells which views need to be focusable. You can put your image views in an array and give it to the focus manager.
    [self.mediaFocusManager installOnViews:self.imageViews];
}
```

Here is an example of a delegate implementation. Please adapt the code to your context.
```objc
#pragma mark - ASMediaFocusDelegate
// Returns an image that represents the media view. This image is used in the focusing animation view. It is usually a small image.
- (UIImage *)mediaFocusManager:(ASMediaFocusManager *)mediafocus imageForView:(UIView *)view
{
    return ((UIImageView *)view).image;
}

// Returns the final focused frame for this media view. This frame is usually a full screen frame.
- (CGRect)mediaFocusManager:(ASMediaFocusManager *)mediafocus finalFrameforView:(UIView *)view
{
    return self.parentViewController.view.bounds;
}

// Returns the view controller in which the focus controller is going to be added. This can be any view controller, full screen or not.
- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediafocus
{
    return self.parentViewController;
}

// Returns a local media path, it must be an image path. This path is used to create an image at full screen.
- (NSString *)mediaFocusManager:(ASMediaFocusManager *)mediafocus mediaPathForView:(UIView *)view
{
    NSString *path;
    NSString *name;
    
    // Here, images are accessed through their name "1f.jpg", "2f.jpg", …
    name = [NSString stringWithFormat:@"%df", ([self.imageViews indexOfObject:view] + 1)];
    path = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg"];
    
    return path;
}

```

###Configure
You can change the main background color as well as the animation duration.

## ARC
ASMediaFocusManager needs ARC.

## Licence
ASMediaFocusManager is available under the MIT license. See the LICENSE file for more info.


