//
//  EUExQupai.m
//  EUExQupai
//
//  Created by 杨广 on 16/4/6.
//  Copyright © 2016年 杨广. All rights reserved.
//

#import "EUExQupai.h"
#import "EUtility.h"

@interface EUExQupai ()
@property(nonatomic,assign) CGFloat minDuration;
@property(nonatomic,assign) CGFloat maxDuration;
@property(nonatomic,assign) CGFloat rate;
@property(nonatomic,assign) CGFloat width;
@property(nonatomic,assign) CGFloat height;
@property(nonatomic,assign) CGFloat beautySkinRate;
@property(nonatomic,strong) UIViewController *controller;
@property(nonatomic,strong) ACJSFunctionRef *func;
@property int cameraFrontOn;
@property BOOL openBeautySkin ;
@end
@implementation EUExQupai

-(void)init:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    ACJSFunctionRef *func = ac_JSFunctionArg(inArguments.lastObject);
    id info=[inArguments[0] ac_JSONValue];
    NSString *appKey = [info objectForKey:@"appKey"];
    NSString *appSecret = [info objectForKey:@"appSecret"];
    NSString *space = [info objectForKey:@"space"];
    
    
    [[QupaiSDK shared] registerAppWithKey:appKey secret:appSecret space:space success:^(NSString *accessToken){
        NSLog(@"%@",accessToken);
        NSDictionary *dic = [NSDictionary dictionary];
        
        dic = @{@"status" :@(0)};
        NSString *results = [dic ac_JSONFragment];
        //NSString *jsString = [NSString stringWithFormat:@"if(uexQupai.cbInit){uexQupai.cbInit('%@');}",results];
        //[EUtility brwView:self.meBrwView evaluateScript:jsString];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexQupai.cbInit" arguments:ACArgsPack(results)];
        [func executeWithArguments:ACArgsPack(@(0))];
    } failure:^(NSError *error) {
        NSDictionary *dic = [NSDictionary dictionary];
        dic = @{@"status" :@(1),@"error":@(error.code)};
        NSString *results = [dic ac_JSONFragment];
        //NSString *jsString = [NSString stringWithFormat:@"if(uexQupai.cbInit){uexQupai.cbInit('%@');}",results];
        //[EUtility brwView:self.meBrwView evaluateScript:jsString];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexQupai.cbInit" arguments:ACArgsPack(results)];
        [func executeWithArguments:ACArgsPack(@(1),@(error.code))];
    }];
    
}
-(void)config:(NSMutableArray *)inArguments{
    if(inArguments.count<1){
        return;
    }
    id info=[inArguments[0] ac_JSONValue];
    self.minDuration = [[info objectForKey:@"minDuration"] floatValue]?:2;
    self.maxDuration = [[info objectForKey:@"maxDuration"] floatValue]?:8;
    self.rate = [[info objectForKey:@"rate"] floatValue]?:2000000;
    self.width = [[info objectForKey:@"width"] floatValue]?:320;
    self.height = [[info objectForKey:@"height"] floatValue]?:480;
    if ([info objectForKey:@"cameraFrontOn"] == nil) {
        self.cameraFrontOn = 1;
    }else{
        self.cameraFrontOn = [[info objectForKey:@"cameraFrontOn"] boolValue]?1:0;
    }
    if ([info objectForKey:@"openBeautySkin"] == nil) {
        self.openBeautySkin = YES;
    } else {
        self.openBeautySkin = [[info objectForKey:@"openBeautySkin"] boolValue]?YES:NO;
    }
    
    self.beautySkinRate = [[info objectForKey:@"beautySkinRate"] floatValue]/100?:0.8;
    
    
}
-(void)record:(NSMutableArray *)inArguments{
    ACJSFunctionRef *func = ac_JSFunctionArg(inArguments.lastObject);
    self.func = func;
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
    //[EUtility brwView:self.meBrwView presentModalViewController:recordController animated:YES];
    [[self.webViewEngine viewController] presentViewController:recordController animated:YES completion:nil];
    
    
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
        NSData *data = [[NSData alloc]initWithContentsOfFile:videoPath];
        NSString *videoPath1 = [self saveMessageDataToLocalPath:data];
        UIImage *image = [[UIImage alloc]initWithContentsOfFile:thumbnailPath];
        thumbnailPath = [self saveImage:image quality:0.8 usePng:YES];
        dic = @{@"thumbPath":thumbnailPath,@"videoPath":videoPath1};
        NSString *results = [dic ac_JSONFragment];
        //NSString *jsString = [NSString stringWithFormat:@"if(uexQupai.cbRecord){uexQupai.cbRecord('%@');}",results];
        //[EUtility brwView:self.meBrwView evaluateScript:jsString];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexQupai.cbRecord" arguments:ACArgsPack(results)];
        [self.func executeWithArguments:ACArgsPack(@(0),dic)];
        self.func = nil;
    }else{
        [self.func executeWithArguments:ACArgsPack(@(1))];
    }
    
    
}
//图片\音频的保存路径
- (NSString *)getImageSaveDirPath{
    NSString *tempPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/apps"];
    NSString *wgtTempPath=[tempPath stringByAppendingPathComponent:AppCanMainWidget().widgetId];
    
    return [wgtTempPath stringByAppendingPathComponent:@"uexQupai"];
}
//图片\音频的保存路径
- (NSString *)getAudioSaveDirPath{
    NSString *tempPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/apps"];
    NSString *wgtTempPath=[tempPath stringByAppendingPathComponent:AppCanMainWidget().widgetId];
    
    return [wgtTempPath stringByAppendingPathComponent:@"uexQupai"];
}
-(NSString *) saveMessageDataToLocalPath:(NSData *)messageData
{
    
    if (!messageData) {
        return nil;
    }
    NSFileManager *fmanager = [NSFileManager defaultManager];
    NSString *uexImageSaveDir=[self getAudioSaveDirPath];
    if (![fmanager fileExistsAtPath:uexImageSaveDir]) {
        [fmanager createDirectoryAtPath:uexImageSaveDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *timeStr = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSinceReferenceDate]];
    
    NSString *imgName = [NSString stringWithFormat:@"%@.%@",[timeStr substringFromIndex:([timeStr length]-6)],@"mp4"];
    NSString *imgTmpPath = [uexImageSaveDir stringByAppendingPathComponent:imgName];
    if ([fmanager fileExistsAtPath:imgTmpPath]) {
        [fmanager removeItemAtPath:imgTmpPath error:nil];
    }
    if([messageData writeToFile:imgTmpPath atomically:YES]){
        return imgTmpPath;
    }else{
        return nil;
    }
    
    
}

- (NSString *)saveImage:(UIImage *)image quality:(CGFloat)quality usePng:(BOOL)usePng{
    NSData *imageData;
    NSString *imageSuffix;
    if(usePng){
        imageData=UIImagePNGRepresentation(image);
        imageSuffix=@"png";
    }else{
        imageData=UIImageJPEGRepresentation(image, quality);
        imageSuffix=@"jpg";
    }
    
    
    if(!imageData) return nil;
    
    NSFileManager *fmanager = [NSFileManager defaultManager];
    
    NSString *uexImageSaveDir=[self getImageSaveDirPath];
    if (![fmanager fileExistsAtPath:uexImageSaveDir]) {
        [fmanager createDirectoryAtPath:uexImageSaveDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *timeStr = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSinceReferenceDate]];
    
    NSString *imgName = [NSString stringWithFormat:@"%@.%@",[timeStr substringFromIndex:([timeStr length]-6)],imageSuffix];
    NSString *imgTmpPath = [uexImageSaveDir stringByAppendingPathComponent:imgName];
    if ([fmanager fileExistsAtPath:imgTmpPath]) {
        [fmanager removeItemAtPath:imgTmpPath error:nil];
    }
    if([imageData writeToFile:imgTmpPath atomically:YES]){
        return imgTmpPath;
    }else{
        return nil;
    }
    
}



@end
