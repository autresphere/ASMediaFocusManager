## ASMediaFocusManager
ASMediaFocusManager gives the ability to focus on any thumbnail image by a simple tap. The thumbnail image is automatically animated to a focused fullscreen image view. Another tap on the focused view (or on the 'Done' button) shrinks the image back to its initial position.

Each thumbnail image view may have its own transform, the focus and defocus animations take care of any initial transform.

Works on iPhone and iPad.

<div class="macbuildserver-block">
    <a class="macbuildserver-button" href="http://macbuildserver.com/project/github/build/?xcode_project=Example%2FASMediaFocusExemple.xcodeproj&amp;target=ASMediaFocusExemple&amp;repo_url=https%3A%2F%2Fgithub.com%2Fautresphere%2FASMediaFocusManager&amp;build_conf=Release" target="_blank"><img src="http://com.macbuildserver.github.s3-website-us-east-1.amazonaws.com/button_up.png"/></a><br/><sup><a href="http://macbuildserver.com/github/opensource/" target="_blank">by MacBuildServer</a></sup>
</div>

![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/video.gif) 

## Orientation
The focused view is automatically adapted to the screen orientation even if your main view controller is portrait only.

Because orientation management was different on iOS 5, this class does not work on iOS 5 and below (although it should not be hard to adapt it).
## Image content modes
For now, only `UIViewContentModeScaleAspectFit` and `UIViewContentModeScaleAspectFill` are supported, but these modes are the most widely used.

In case of `UIViewContentModeScaleAspectFill`, the view is expanded in order to show the image in full.

![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/videoAspectFill.gif) 

If you want other content modes to be supported, please drop me a line. You can even try a pull request, which would be much appreciated!

## Image size
When focused, an image is shown fullscreen even if the image is smaller than the screen resolution. In this case no interactive zoom is available.

All Image sizes are supported.

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
// Returns an image view that represents the media view. This image from this view is used in the focusing animation view. It is usually a small image.
- (UIImageView *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager imageViewForView:(UIView *)view;
{
    return (UIImageView *)view;
}

// Returns the final focused frame for this media view. This frame is usually a full screen frame.
- (CGRect)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager finalFrameForView:(UIView *)view
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

If you need to focus a view programmatically, you can call `startFocusingView` as long as the view is focusable.

```objc
[self.mediaFocusManager startFocusingView:mediaView];
```

###Configure
Here is the things you can configure:

* focused background color 
* animation duration
* enable/disable elastic animation
* enable/disable zooming by pinch
* close focused view by tap, vertical swipe or through a "Done" button

### Hiding the status bar
On iOS 7, if you want to hide or show the status bar when a view is focused or defocused, you can use optional delegate methods `[ASMediaFocusManager mediaFocusManagerWillAppear:]` and `[ASMediaFocusManager mediaFocusManagerWillDisappear:]`.

Here is an example on how to hide and show the status bar. As the delegate methods are called inside an animation block, the status bar will be hidden or shown with animation.
```objc
- (void)mediaFocusManagerWillAppear:(ASMediaFocusManager *)mediaFocusManager
{
    self.statusBarHidden = YES;
	[self setNeedsStatusBarAppearanceUpdate];
}

- (void)mediaFocusManagerWillDisappear:(ASMediaFocusManager *)mediaFocusManager
{
    self.statusBarHidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

// statusBarHidden is defined as a property.
@property (nonatomic, assign) BOOL statusBarHidden;

```


##Todo
* Fix image jump on orientation change when fullscreen image is zoomed (only when parent ViewController supports UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown)
* Improve the elastic (ie natural) effect on focus and defocus rotation.
* Support movie media.
* Close focus view by vertical swipe like in facebook app (partly done thanks to @harishkashyap, Feb 09, 2015).
* Media browsing by horizontal swipe in fullscreen.
* ~~Hide accessory views (button and label) when view is zoomed.~~ (March 5, 2014)

## ARC
ASMediaFocusManager needs ARC.

## Licence
ASMediaFocusManager is available under the MIT license, Copyright (c) 2014 AutreSphere [@autresphere](http://twitter.com/autresphere).



