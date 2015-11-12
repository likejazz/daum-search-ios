//
//  ViewController.m
//
//  Copyright © 2015 Sang-Kil Park Some rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

NSString *_DEFAULT_URL = @"http://m.daum.net";
NSString *_SEARCH_URL = @"https://m.search.daum.net/search?w=tot&q=";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadBrowser:_DEFAULT_URL];

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];

    // Setting the swipe direction.
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];

    // Adding the swipe gesture on WebView
    [_webView addGestureRecognizer:swipeLeft];
    [_webView addGestureRecognizer:swipeRight];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* -- */

// Load WebKit viewer with specific URL
- (void)loadBrowser:(NSString *)url {
    NSURL *urlNS = [NSURL URLWithString:url];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:urlNS];
    [_webView loadRequest:urlRequest];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {

    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        if (_webView.canGoForward) {
            [_webView goForward];
        }
    }

    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        if (_webView.canGoBack) {
            [_webView goBack];
        }
    }
}

/* -- */

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_searchBar resignFirstResponder];

    NSString *q = _searchBar.text;

    if ([q length] != 0) {
        [self loadBrowser:[NSString stringWithFormat:@"%@%@",
                           _SEARCH_URL,
                           [q stringByAddingPercentEncodingWithAllowedCharacters: // Query encoding for HTTP request
                                   [NSCharacterSet URLHostAllowedCharacterSet]]
                           ]];
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    NSLog(@"focus");
    // TODO: select all text in UITextField
}

@end