#import "ViewController.h"
@import MixedSourceFramework;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    SwiftLogger *swiftLogger = [[SwiftLogger alloc] init];

    [swiftLogger swiftLog:@"Hello Swift, from the ViewController!"];

    [self.view setBackgroundColor:[UIColor greenColor]];
}

@end
