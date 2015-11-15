//
//  ViewController.m
//
//  Copyright © 2015 Sang-Kil Park Some rights reserved.
//

#import "ViewController.h"
#import "TUSafariActivity.h"
#import "ARChromeActivity.h"

@interface ViewController ()

@property (nonatomic, strong) NSTimer *fakeProgressTimer;
@property (nonatomic, assign) BOOL fakeProgressBarIsLoading;

@end

@implementation ViewController

UIView *grayOverlay;

NSString *_DEFAULT_URL = @"http://m.daum.net";
NSString *_SEARCH_URL = @"https://m.search.daum.net/search?w=tot&q=";

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    NSAssert([self.webView isKindOfClass:[UIWebView class]], @"Your webView outlet is not correctly connected.");
    NSAssert(self.back, @"Your back button outlet is not correctly connected.");
    NSAssert((self.back.target == self.webView) && (self.back.action = @selector(goBack)), @"Your back button action is not connected to goBack.");

    [self loadURL:_DEFAULT_URL];

    // Setting the swipe gesture on WebView.
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [_webView addGestureRecognizer:swipeRight];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Internal Handlers

// navigate WebView with specific URL
- (void)loadURL:(NSString *)url {
    NSURL *urlNS = [NSURL URLWithString:url];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:urlNS];
    [_webView loadRequest:urlRequest];
}

// swipe gesture 구현. 좌 → 우 인 경우 '뒤로가기' 이벤트만 임시로 구현해본다.
- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        if (_webView.canGoBack) {
            // Implements swipe transition animation.
            CATransition *animation = [CATransition animation];
            [animation setDelegate:self];
            [animation setType:kCATransitionPush];
            [animation setSubtype:kCATransitionFromLeft];
            [animation setDuration:0.40];
            [animation setTimingFunction:
                    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [_webView.layer addAnimation:animation forKey:kCATransition];

            [_webView goBack];
        }
    }
}

// toolbar 버튼 활성/비활성 구성
- (void)updateButtons {
    self.back.enabled = self.webView.canGoBack;
    self.forward.enabled = self.webView.canGoForward;
}

#pragma mark - UISearchBar Handlers

// '검색'이 진행될때
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    // focus out
    [_searchBar resignFirstResponder];
    
    NSString *q = _searchBar.text;
    if ([q length] != 0) {
        [self loadURL:[NSString stringWithFormat:@"%@%@",
                                                 _SEARCH_URL,
                                                 [q stringByAddingPercentEncodingWithAllowedCharacters: // Query encoding for HTTP request
                                                         [NSCharacterSet URLHostAllowedCharacterSet]]
        ]];
    }

    // remove dimmed WebView overlay.
    [grayOverlay removeFromSuperview];
}

// '검색'창에 포커스를 가져갔을때
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // self.webView is the one that needs to be grayed out.
    grayOverlay = [[UIView alloc] initWithFrame:_webView.frame];

    // UIColor 체계 참고 http://www.iosing.com/2011/11/uicolor-understanding-colour-in-ios/
    [grayOverlay setBackgroundColor:[UIColor grayColor]];
    [grayOverlay setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0.9]];
    [self.view addSubview:grayOverlay];
}

// '검색'창에서 벗어났을때(재현되지 않는다)
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [grayOverlay removeFromSuperview];
}

// 터치 이벤트 중 grayOverlay 인 경우에만 overlay 를 걷어내고 검색창 focus out 하도록 이벤트 설정
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if ([touch view] == grayOverlay) {
        // remove and focus out WebView overlay
        [grayOverlay removeFromSuperview];
        [_searchBar resignFirstResponder];
    }
}

#pragma mark - WebView Handlers

// WebView 호출 시작
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self fakeProgressViewStartLoading];
    [self updateButtons];

    return YES;
}

// WebView 로딩 종료
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self fakeProgressBarStopLoading];
    [self updateButtons];
}

#pragma mark - Fake Progress Bar Control (UIWebView)

- (void)fakeProgressViewStartLoading {
    if (!self.fakeProgressBarIsLoading) {
        [self.progressView setProgress:0.1f animated:NO];
        [self.progressView setAlpha:1.0f];

        self.fakeProgressBarIsLoading = YES;
    }

    if(!self.fakeProgressTimer) {
        self.fakeProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f target:self selector:@selector(fakeProgressTimerDidFire:) userInfo:nil repeats:YES];
    }
}

- (void)fakeProgressBarStopLoading {
    if(self.fakeProgressTimer) {
        [self.fakeProgressTimer invalidate];

        self.fakeProgressBarIsLoading = NO;
    }

    if(self.progressView) {
        [self.progressView setProgress:1.0f animated:YES];
        [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.progressView setAlpha:0.0f];
        } completion:^(BOOL finished) {
            [self.progressView setProgress:0.0f animated:NO];
        }];
    }
}

- (void)fakeProgressTimerDidFire:(id)sender {
    CGFloat increment = 0.005/(self.progressView.progress + 0.2);
    if([self.webView isLoading]) {
        CGFloat progress = (self.progressView.progress < 0.75f) ? self.progressView.progress + increment : self.progressView.progress + 0.0005;
        if(self.progressView.progress < 0.95) {
            [self.progressView setProgress:progress animated:YES];
        }
    }
}

#pragma mark - IBActions

// '홈' 버튼 클릭시
- (IBAction)home:(id)sender {
    [self loadURL:_DEFAULT_URL];
}

// '공유' 버튼 클릭시
// 기본 공유 화면에 사파리, 크롬 공유하기 추가
- (IBAction)share:(id)sender {
    NSURL *URLForActivityItem = self.webView.request.URL;

    if (URLForActivityItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
            TUSafariActivity *safariActivity = [[TUSafariActivity alloc] init];
            ARChromeActivity *chromeActivity = [[ARChromeActivity alloc] init];

            NSMutableArray *activities = [[NSMutableArray alloc] init];
            [activities addObject:safariActivity];
            [activities addObject:chromeActivity];

            UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[URLForActivityItem] applicationActivities:activities];

            // http://stackoverflow.com/questions/25644054/uiactivityviewcontroller-crashing-on-ios8-ipads
            // iPhone
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                [self presentViewController:controller animated:YES completion:nil];
            }
            // iPad
            else {
                // Change Rect to position Popover
                UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:controller];
                [popup presentPopoverFromRect:CGRectMake(self.view.frame.size.width / 1.1, self.view.frame.size.height / 1.06, 0, 0) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        });
    }
}

@end