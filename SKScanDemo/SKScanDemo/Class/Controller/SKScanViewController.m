//
//  SKScanViewController.m
//  SKScanDemo
//
//  Created by XunLi on 2017/6/27.
//  Copyright © 2017年 AlexanderYeah. All rights reserved.
//

#import "SKScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView_extra.h"

#define kBorderWidth 230 // 框框的宽度
#define kInfoLblHeight 40 // 框框上方的提示信息
#define kLightBtnWidth 60 // 手电筒按钮
#define kLightBtnHeight 80

@interface SKScanViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic,strong)AVCaptureSession *session;
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *layer;

/**
 扫描横线
 */
@property (nonatomic,strong)UIImageView *scanlineImgView;

@property (nonatomic,strong)UIImageView *borderImgView;


/**
 扫描线的原始X值 和 Y 值
 */
@property (nonatomic,assign)CGFloat scanlineX;

@property (nonatomic,assign)CGFloat scanlineY;

/**
 是否开启闪光灯
 */
@property (nonatomic,assign)BOOL isOpenFlash;
// 为了开启闪光灯，才设为全局变量
@property (strong,nonatomic)AVCaptureDeviceInput * input;

@end

@implementation SKScanViewController

/*
    功能稍微描述下
    1 实现扫描动画
    2 扫描到结果，语音和震动
    3 开启灯光
    4 从相册选择照片进行扫描
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 1 创建UI
    [self setupUI];
    // 2 开始扫描
    [self beginScan];
}

#pragma mark - setupUI
-(void)setupUI
{
    // 1 扫描二维码的边框
    UIImageView *borderImgView = [[UIImageView alloc]init];
    _borderImgView = borderImgView;
    borderImgView.image = [UIImage imageNamed:@"qrcode_border"];
    borderImgView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:borderImgView];
    
    [borderImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(230);
        make.height.equalTo(230);
        make.centerX.equalTo(self.view.mas_centerX);
        make.centerY.equalTo(self.view.mas_centerY);
    }];
    
    // 2 扫描的横线
    UIImageView *scanlineImgView = [[UIImageView alloc]init];
    _scanlineImgView = scanlineImgView;

    scanlineImgView.image = [UIImage imageNamed:@"scan_line"];
    [self.view addSubview:scanlineImgView];
    
    [scanlineImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(2);
        make.width.equalTo(230);
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.view.mas_centerY).offset(115);
    }];
    [_scanlineImgView layoutIfNeeded];
    _scanlineX = _scanlineImgView.frame.origin.x;
    _scanlineY = _scanlineImgView.frame.origin.y;
    NSLog(@"scanlineX_%f\n_scanlineY__%f",_scanlineX,_scanlineY);
    [self startScanAnim];
    
    //3 扫描框上方的提示信息
    UILabel *infoLbl = [[UILabel alloc]init];
    infoLbl.text = @"请将二维码对准框框,即可自动扫描";
    infoLbl.textAlignment = NSTextAlignmentCenter;
    infoLbl.font = [UIFont systemFontOfSize:16.0f];
    infoLbl.textColor = [UIColor whiteColor];
    [self.view addSubview:infoLbl];
    
    [infoLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(kScreenWidth);
        make.height.equalTo(kInfoLblHeight);
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.view.mas_centerY).offset(-170);
    }];
    
    // 4 手电筒照片
    UIButton *lightBtn = [UIButton  buttonWithType:UIButtonTypeCustom];
    [lightBtn setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_flash_nor"] forState:UIControlStateNormal];
  
    [lightBtn addTarget:self action:@selector(lightBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:lightBtn];
    self.isOpenFlash = NO;
    [lightBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(kLightBtnWidth);
        make.height.equalTo(67);
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.view.mas_centerY).offset(200);
  
    }];
    
    
    
}

#pragma mark - 二维码的读取
-(void)beginScan
{
    // 1 创建捕捉会话
    _session = [[AVCaptureSession alloc]init];
    
    // 2 添加输入设备,从哪里获取数据
    // 2.1 实例化device ，从摄像头获取数据
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    self.input = input;
    // 2.2 添加输入设备
    [_session addInput:input];
    
    // 3 添加输出设备
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc]init];
    // 3.1 设置代理，从代理方法中取出数据
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    // 3.2
    [_session addOutput:output];
    
    // 3.3 必须在添加之后设置元数据的类型为二维码
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    // 4 添加扫描图层
#pragma mark - 此处把扫描嵌入到最底层,不然的话，把扫描框给覆盖了
    _layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _layer.frame = self.view.bounds;
    
    [self.view.layer insertSublayer:_layer atIndex:0];
    
    // 5 开始扫描
    [_session startRunning];
    
    
}

#pragma mark - output 回调方法,当扫描到数据的时候，就会执行该方法
/**
 *  <#Description#>
 *
 *  @param captureOutput   <#captureOutput description#>
 *  @param metadataObjects 返回的数组，可以拿到我们想要的数据，可以判断数组是否为空，从未知道是否扫描到数据
 *  @param connection      <#connection description#>
 */
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count > 0) {
        NSLog(@"成功地扫描到数据");
        // 0 声音震动和声音提醒
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        AudioServicesPlaySystemSound(1109);
        // 1 获取扫描结果
        AVMetadataMachineReadableCodeObject *object = [metadataObjects lastObject];
        NSLog(@"%@",object.stringValue);
        // 2 停止扫描
        [self.session stopRunning];
        // 3 移除图层
        [self.layer removeFromSuperlayer];
        // 4 然后就返回吧
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        NSLog(@"没有扫描到数据");
    }
    
}


#pragma mark - 扫描动画
- (void)startScanAnim
{
    // 所谓扫描动画
    [_scanlineImgView layoutIfNeeded];
    NSLog(@"scanlineX_%f\n_scanlineY__%f",_scanlineX,_scanlineY);
    
#pragma mark - 此处的坑[UIView setAnimationRepeatCount:MAXFLOAT];

    [UIView animateWithDuration:2.0f animations:^{
         [UIView setAnimationRepeatCount:MAXFLOAT];
        _scanlineImgView.frame = CGRectMake(_scanlineX, _scanlineY + 230, 230, 2);
    } completion:^(BOOL finished) {
        _scanlineImgView.frame = CGRectMake(_scanlineX, _scanlineY, 230, 2);

    }];
    [_scanlineImgView layoutIfNeeded];
}




#pragma mark - 闪光灯开启
- (void)lightBtnClick:(UIButton *)btn
{
    if (_isOpenFlash) {
        // 1 切换按钮的
        [btn setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_flash_nor"] forState:UIControlStateNormal];
        _isOpenFlash = NO;
    }else{
        // 1 切换按钮的
        [btn setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_scan_off"] forState:UIControlStateNormal];
        _isOpenFlash = YES;
    }
    

    
    // 2 开启闪光灯
    [self openFlashLight];
}

#pragma mark - 闪关灯开启的方法抽取
- (void)openFlashLight
{
    // 获取设备
    AVCaptureDevice *device =  [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 当前的设备会根据手机自己的状态 然后去切换自己状态
    if ([device hasTorch] && [device hasFlash]){
        AVCaptureTorchMode torch = self.input.device.torchMode;
        switch (self.input.device.torchMode) {
            case AVCaptureTorchModeAuto:
                break;
            case AVCaptureTorchModeOff:
                torch = AVCaptureTorchModeOn;
                break;
            case AVCaptureTorchModeOn:
                torch = AVCaptureTorchModeOff;
                break;
            default:
                break;
        }
        [self.input.device lockForConfiguration:nil];
        self.input.device.torchMode = torch;
        [self.input.device unlockForConfiguration];
    }
}

@end
