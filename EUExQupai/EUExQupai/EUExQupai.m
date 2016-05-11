//
//  EUExQupai.m
//  EUExQupai
//
//  Created by 杨广 on 16/4/6.
//  Copyright © 2016年 杨广. All rights reserved.
//

#import "EUExQupai.h"
#import "EUtility.h"
#import "JSON.h"
@interface EUExQupai ()
@property(nonatomic,assign) CGFloat minDuration;
@property(nonatomic,assign) CGFloat maxDuration;
@property(nonatomic,assign) CGFloat rate;
@property(nonatomic,assign) CGFloat width;
@property(nonatomic,assign) CGFloat height;
@property(nonatomic,assign) CGFloat beautySkinRate;
@property(nonatomic,strong) UIViewController *controller;
@property int cameraFrontOn;
@property BOOL openBeautySkin ;
@end
@implementation EUExQupai
- (id)initWithBrwView:(EBrowserView *)eInBrwView{
    if (self = [super initWithBrwView:eInBrwView]){
        
    }
    return self;
    
}
-(void)init:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info=[inArguments[0] JSONValue];
    NSString *appKey = [info objectForKey:@"appKey"];
     NSString *appSecret = [info objectForKey:@"appSecret"];
     NSString *space = [info objectForKey:@"space"];

    
    [[QupaiSDK shared] registerAppWithKey:appKey secret:appSecret space:space success:^(NSString *accessToken){
        NSLog(@"%@",accessToken);
        NSDictionary *dic = [NSDictionary dictionary];

     dic = @{@"status" :@(0)};
        NSString *results = [dic JSONFragment];
        NSString *jsString = [NSString stringWithFormat:@"if(uexQupai.cbInit){uexQupai.cbInit('%@');}",results];
        [EUtility brwView:self.meBrwView evaluateScript:jsString];
    } failure:^(NSError *error) {
        NSDictionary *dic = [NSDictionary dictionary];
        dic = @{@"status" :@(1),@"error":@(error.code)};
        NSString *results = [dic JSONFragment];
        NSString *jsString = [NSString stringWithFormat:@"if(uexQupai.cbInit){uexQupai.cbInit('%@');}",results];
        [EUtility brwView:self.meBrwView evaluateScript:jsString];
    }];
    
}
-(void)config:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info=[inArguments[0] JSONValue];
    self.minDuration = [[info objectForKey:@"minDuration"] floatValue]?:2;
    self.maxDuration = [[info objectForKey:@"maxDuration"] floatValue]?:8;
    self.rate = [[info objectForKey:@"rate"] floatValue]?:2000000;
    self.width = [[info objectForKey:@"width"] floatValue]?:320;
    self.height = [[info objectForKey:@"height"] floatValue]?:480;
    self.cameraFrontOn = [[info objectForKey:@"cameraFrontOn"] boolValue]?0:1;
    self.openBeautySkin = [[info objectForKey:@"openBeautySkin"] boolValue]?NO:YES;
    self.beautySkinRate = [[info objectForKey:@"beautySkinRate"] floatValue]/100?:0.8;
    
    
}
-(void)record:(NSMutableArray *)inArguments{
    QupaiSDK *sdk = [QupaiSDK shared];
    [sdk setDelegte:(id<QupaiSDKDelegate>)self];
    //可选设置
    sdk.thumbnailCompressionQuality = 0.3;
    sdk.combine = YES;
    sdk.progressIndicatorEnabled = YES;
    sdk.beautySwitchEnabled = self.openBeautySkin;
    sdk.flashSwitchEnabled = YES;
    sdk.beautyDegree = self.beautySkinRate;
    sdk.bottomPanelHeight = 120;
    sdk.recordGuideEnabled = YES;
    sdk.cameraPosition =  self.cameraFrontOn;
    /*基本设置*/
    //CGSize videoSize = CGSizeMake([EUtility screenWidth], [EUtility screenHeight]-168);
    CGSize videoSize = CGSizeMake(self.width, self.height);
    UIViewController *recordController = [sdk createRecordViewControllerWithMinDuration:self.minDuration
                                                                            maxDuration:self.maxDuration
                                                                                bitRate:self.rate
                                                                              videoSize:videoSize];
    self.controller = recordController;
    [EUtility brwView:self.meBrwView presentModalViewController:recordController animated:YES];
   


}
#pragma mark - QupaiSDK Delegate

- (void)qupaiSDKCancel:(QupaiSDK *)sdk{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.controller dismissViewControllerAnimated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }];
    });
    
}

- (void)qupaiSDK:(QupaiSDK *)sdk compeleteVideoPath:(NSString *)videoPath thumbnailPath:(NSString *)thumbnailPath
{
    NSLog(@"Qupai SDK compelete %@",videoPath);
    NSDictionary *dic = [NSDictionary dictionary];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.controller dismissViewControllerAnimated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }];
    });
    if (videoPath && thumbnailPath) {
        dic = @{@"thumbPath":thumbnailPath,@"videoPath":videoPath};
        NSString *results = [dic JSONFragment];
        NSString *jsString = [NSString stringWithFormat:@"if(uexQupai.cbRecord){uexQupai.cbRecord('%@');}",results];
        [EUtility brwView:self.meBrwView evaluateScript:jsString];
    }
    
    
}



@end
