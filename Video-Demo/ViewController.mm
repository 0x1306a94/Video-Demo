//
//  ViewController.m
//  Video-Demo
//
//  Created by king on 2018/11/9.
//  Copyright © 2018 king. All rights reserved.
//


#import "ViewController.h"
#import "FetchVideoController.h"

#import <Photos/Photos.h>

#import <MBProgressHUD/MBProgressHUD.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <FLEX/FLEX.h>



@interface ViewController ()
@property (nonatomic, assign) BOOL requestPermissioned;
@property (weak, nonatomic) IBOutlet UIButton *fecthVideoButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.requestPermissioned = NO;
    self.fecthVideoButton.enabled = NO;
    [self showFLEX:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.requestPermissioned) return;
    self.requestPermissioned = YES;
    @weakify(self);
    [[self requestPermission] subscribeNext:^(RACTuple  * _Nullable tuple) {
        @strongify(self);
        RACTupleUnpack(NSNumber *flag, NSString *tips) = tuple;
        self.fecthVideoButton.enabled = [flag boolValue];
        if ([flag boolValue]) {
            
        } else if (tips && tips.length > 0) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = tips;
            [hud hideAnimated:YES afterDelay:3.0];
        }
    } completed:^{
        NSLog(@"completed");
    }];
}

- (RACSignal *)requestPermission {
    return [[[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined) {
            // 还未请求过权限
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                NSLog(@"status: %ld", status);
                if (status == PHAuthorizationStatusAuthorized) {
                    [subscriber sendNext:RACTuplePack(@YES, nil)];
                } else {
                    // 拒绝授权
                    [subscriber sendNext:RACTuplePack(@NO, @"拒绝授权,无法访问相册")];
                }
                [subscriber sendCompleted];
            }];
        } else if (status == PHAuthorizationStatusAuthorized) {
            // 已授权
            [subscriber sendNext:RACTuplePack(@YES, nil)];
            [subscriber sendCompleted];
        } else if (status == PHAuthorizationStatusRestricted
                   || status == PHAuthorizationStatusDenied) {
            // 无权限
            [subscriber sendNext:RACTuplePack(@NO, @"无权限,无法访问相册")];
            [subscriber sendCompleted];
        }
        return nil;
    }] replayLazily] deliverOnMainThread];
}

- (IBAction)showFLEX:(UIBarButtonItem *)sender {
    [[FLEXManager sharedManager] toggleExplorer];
}

- (IBAction)fetchVideo:(UIButton *)sender {
    FetchVideoController *vc = [[FetchVideoController alloc] init];
    [self.navigationController showViewController:vc sender:nil];
}

@end
