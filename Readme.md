## ASMediaFocusManager
ASMediaFocusManager gives the ability to focus on any thumbnail image by a simple tap. The thumbnail image is automatically animated to a focused fullscreen image view. Another tap on the focused view shrinks the image back to its initial position.

Each thumbnail image view may have its own transform, the focus and defocus animations take care of any initial transform.

Works on iPhone and iPad.

<div class="macbuildserver-block">
    <a class="macbuildserver-button" href="http://macbuildserver.com/project/github/build/?xcode_project=Example%2FASMediaFocusExemple.xcodeproj&amp;target=ASMediaFocusExemple&amp;repo_url=https%3A%2F%2Fgithub.com%2Fautresphere%2FASMediaFocusManager&amp;build_conf=Release" target="_blank"><img src="http://com.macbuildserver.github.s3-website-us-east-1.amazonaws.com/button_up.png"/></a><br/><sup><a href="http://macbuildserver.com/github/opensource/" target="_blank">by MacBuildServer</a></sup>
</div>

![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/video.gif) 

## Orientation
The focused view is automatically adapted to the screen orientation even if your main view controller is portrait only.

Because orientation management is different between iOS 5 and 6, this class is for iOS 6 only (although it should not be hard to adapt it to iOS 5).
## Use It
Add `pod 'ASMediaFocusManager'` to your Podfile or copy the whole `ASMediaFocusManager` folder in your project.

* Create a `ASMediaFocusManager`
* Implement its delegate (`ASMediaFocusDelegate`)
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
// Returns an image that represents the media view. This image is used in the focusing animation view.
// It is usually a small image.
- (UIImage *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager imageForView:(UIView *)view
{
    return ((UIImageView *)view).image;
}

// Returns the final focused frame for this media view. This frame is usually a full screen frame.
- (CGRect)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager finalFrameforView:(UIView *)view
{
    return self.parentViewController.view.bounds;
}

// Returns the view controller in which the focus controller is going to be added.
// This can be any view controller, full screen or not.
- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediaFocusManager
{
    return self.parentViewController;
}

// Returns an URL where the image is stored. This URL is used to create an image at full screen. The URL may be local (file://) or distant (http://).
- (NSURL *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaURLForView:(UIView *)view
{
    NSString *path;
    NSString *name;
    NSURL *url;
    
    // Here, images are accessed through their name "1f.jpg", "2f.jpg", …
    name = [NSString stringWithFormat:@"%df", ([self.imageViews indexOfObject:view] + 1)];
    path = [[NSBundle mainBundle] pathForResource:name ofType:@"jpg"];
    
    url = [NSURL fileURLWithPath:path];
    
    return url;
}

// Returns the title for this media view. Return nil if you don't want any title to appear.
- (NSString *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager titleForView:(UIView *)view
{
	return @"My title";
}


```

###Configure
Here is the things you can configure:

* focused background color 
* animation duration
* enable/disable elastic animation
* enable/disable zooming by pinch
* close focused view either by tap or through a "Done" button

##Todo
* Fix image jump on orientation change when fullscreen image is zoomed
* Improve the elastic (ie natural) effect on focus and defocus rotation.
* Support movie media.
* Close focus view by vertical swipe like in facebook app.
* Media browsing by horizontal swipe in fullscreen.

## ARC
ASMediaFocusManager needs ARC.

## Licence
ASMediaFocusManager is available under the MIT license. See the LICENSE file for more info.


