//
//  FetchVideoController.m
//  Video-Demo
//
//  Created by king on 2018/11/9.
//  Copyright © 2018 king. All rights reserved.
//

#import "FetchVideoController.h"
#import "FecthVideoCell.h"
#import "SubmitController.h"

#import <Photos/Photos.h>

#import <ReactiveObjC/ReactiveObjC.h>
#import <Masonry/Masonry.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <ZFPlayer/ZFPlayer.h>
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import <ZFPlayer/UIImageView+ZFCache.h>
#import <Aspects/Aspects.h>

static NSString *kVideoCover = @"https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240";

@interface FetchVideoController ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UIImageView *videoView;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;

@property (nonatomic, strong) PHImageManager *imageManager;
@property (nonatomic, strong) NSArray<PHAsset *> *sources;
@property (nonatomic, strong) PHAsset *selectAsset;
@property (nonatomic, strong) AVURLAsset *avAsset;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) ZFPlayerControlView *controlView;

@property (nonatomic, assign) PHImageRequestID requestID;
@end

@implementation FetchVideoController
#if DEBUG
- (void)dealloc
{
    NSLog(@"[%@ dealloc]", NSStringFromClass(self.class));
}
#endif
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.requestID = PHInvalidImageRequestID;
    self.imageManager = [PHImageManager defaultManager];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.videoView];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(@(SCREEN_WIDHT / 16.0 * 9.0));
    }];
    [self.view bringSubviewToFront:self.videoView];
    
    @weakify(self);
    RACSignal *enabledSignal = [RACSignal combineLatest:@[RACObserve(self, selectAsset), RACObserve(self, avAsset)] reduce:^id _Nonnull(PHAsset * _Nullable phAsset, AVURLAsset * _Nullable avAsset) {
        if (phAsset && avAsset) {
            Float64 time = CMTimeGetSeconds(avAsset.duration);
            return @(time >= 5.0);
        }
        return @NO;
    }];
    
    RACCommand *nextCmd = [[RACCommand alloc] initWithEnabled:enabledSignal signalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
        @strongify(self);
        SubmitController *vc = [[SubmitController alloc] init];
        vc.asset = self.avAsset;
        [self.navigationController showViewController:vc sender:nil];
        return [RACSignal empty];
    }];
    
    UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStylePlain target:nil action:nil];
    nextItem.rac_command = nextCmd;
    self.navigationItem.rightBarButtonItem = nextItem;
    
    
    [self fetchVideoSources];
    [self setupPlayer];
    
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.player.viewControllerDisappear = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.player) {
        
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.player.viewControllerDisappear = YES;
}
- (void)setupPlayer {
    @weakify(self);
    self.controlView = [[ZFPlayerControlView alloc] init];
    self.controlView.activity.hidden = YES;
    self.controlView.fastViewAnimated = YES;
//    [self.controlView showTitle:nil coverURLString:kVideoCover fullScreenMode:ZFFullScreenModeLandscape];
    [self.videoView setImageWithURLString:kVideoCover placeholder:nil];
    // 去除速度提示
    [self.controlView.activity aspect_hookSelector:@selector(startAnimating) withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> aspectInfo){
//        NSLog(@"startAnimating");
    } error:nil];
    [self.controlView.activity aspect_hookSelector:@selector(stopAnimating) withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> aspectInfo){
//        NSLog(@"stopAnimating");
    } error:nil];
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
    self.player = [ZFPlayerController playerWithPlayerManager:playerManager containerView:self.videoView];
    self.player.controlView = self.controlView;
    self.player.pauseWhenAppResignActive = NO;
    self.player.orientationWillChange = ^(ZFPlayerController * _Nonnull player, BOOL isFullScreen) {
        @strongify(self);
        [self setNeedsStatusBarAppearanceUpdate];
    };
    
    self.player.playerDidToEnd = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset) {
        @strongify(self);
//        [self.player.currentPlayerManager replay];
        NSLog(@"播放完成");
    };
    self.player.playerReadyToPlay = ^(id<ZFPlayerMediaPlayback>  _Nonnull asset, NSURL * _Nonnull assetURL) {
        NSLog(@"开始播放");
    };
    
    self.selectAsset = (self.sources.count > 0) ? self.sources.firstObject : nil;
    [self fecthAVURLAssetWithPHAsset:self.selectAsset complete:^(AVURLAsset *URLAsset) {
        @strongify(self);
        self.avAsset = URLAsset;
        if (!URLAsset) return;
        self.player.assetURL = URLAsset.URL;
        [self.player playTheNext];
    }];
}

- (void)fecthAVURLAssetWithPHAsset:(PHAsset *)asset complete:(void(^)(AVURLAsset *URLAsset))block {
    if (self.requestID != PHInvalidImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = PHInvalidImageRequestID;
    }
    if (!asset) {
        !block ?: block(nil);
        return;
    }
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    [[PHImageManager defaultManager] requestAVAssetForVideo:self.selectAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!asset) {
                !block ?: block(nil);
                return;
            }
            if (![asset isKindOfClass:AVURLAsset.class]) {
                !block ?: block(nil);
                return;
            }
            !block ?: block(asset);
        });
    }];
}
- (void)fetchVideoSources {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    // 根据创建时间升序排列 最新的在最前面
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    // 只获取视频类型
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    NSMutableArray<PHAsset *> *tmps = [NSMutableArray<PHAsset *> array];
    for (PHAsset *asset in assetsFetchResults) {
        [tmps addObject:asset];
    }
    self.sources = [NSArray<PHAsset *> arrayWithArray:tmps];
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.sources.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FecthVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(FecthVideoCell.class) forIndexPath:indexPath];
    cell.asset = self.sources[indexPath.item];
    return cell;
}
#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    @weakify(self);
    self.selectAsset = self.sources[indexPath.item];
    [self fecthAVURLAssetWithPHAsset:self.selectAsset complete:^(AVURLAsset *URLAsset) {
        @strongify(self);
        self.avAsset = URLAsset;
        if (!URLAsset) return;
        self.player.assetURL = URLAsset.URL;
        [self.player playTheNext];
    }];
}

#pragma mark - lazy
- (UIImageView *)videoView {
    if (!_videoView) {
        _videoView = [[UIImageView alloc] init];
    }
    return _videoView;
}
- (UICollectionViewFlowLayout *)layout {
    if (!_layout) {
        _layout = [[UICollectionViewFlowLayout alloc] init];
        _layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        _layout.minimumLineSpacing = 0;
        _layout.minimumInteritemSpacing = 0;
        _layout.itemSize = CGSizeMake(SCREEN_WIDHT / 3.0, SCREEN_WIDHT / 3.0);
    }
    return _layout;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.layout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.contentInset = UIEdgeInsetsMake((SCREEN_WIDHT / 16.0) * 9.0, 0, 0, 0);
        [_collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(FecthVideoCell.class) bundle:nil] forCellWithReuseIdentifier:NSStringFromClass(FecthVideoCell.class)];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
    }
    return _collectionView;
}
@end
