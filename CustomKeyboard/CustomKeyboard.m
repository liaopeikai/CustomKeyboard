//
//  CustomKeyboard.m
//  CustomKeyboard
//
//  Created by liaopeikai on 2016/11/30.
//  Copyright © 2016年 beichende. All rights reserved.
//

#import "CustomKeyboard.h"

#define Kscale 3.0       // 按钮放大系数
#define Kduration 0.2    // 动画持续时间

@interface CustomKeyboard ()

@property(nonatomic,strong)NSString *password;

@property(nonatomic,strong)UITextView *keyView;
@property(nonatomic,strong)UITextView *tempKeyView;

@property(nonatomic,strong)NSMutableArray *letterArr;
@property(nonatomic,strong)NSMutableArray *numberArr;

@property(nonatomic, strong)PasswordBlock passwordBlock;

@property (nonatomic, assign) CGRect keyViewFrame;

@end


@implementation CustomKeyboard
// 大小写状态(默认1:小写)
NSInteger letterState = 1;
// 循环切换系统键盘一次后再切换为自定义键盘
NSInteger switchNum = 0;

// 单例
static CustomKeyboard * _instance = nil;
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

#pragma mark - 懒加载
- (UITextView *)keyView {
    if (_keyView == nil) {
        _keyView = [[UITextView alloc] init];
    }
    return _keyView;
}

- (UITextView *)tempKeyView {
    if (!_tempKeyView) {
        _tempKeyView = [[UITextView alloc] init];
    }
    return _tempKeyView;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputModeDidChange:) name:UITextInputCurrentInputModeDidChangeNotification object:nil];
    }
    return self;
}

// 外部获取密码接口
- (void)returnPasswordBlock:(PasswordBlock)block {
    self.passwordBlock = block;
}

- (NSString *)getPassword {
    return self.password;
}

#pragma mark ---- 键盘弹起和屏幕旋转
- (void)keyboardWillShow:(NSNotification *)notification {
    // 系统键盘弹起会回调多次（这里是回调2次），从而接收都多次通知。设置_instance结合单例即可只执行一次
    if (_instance != nil) {
        [self keyboardDidShow];
        _instance = nil;
    }
}

- (void)orientChange:(NSNotification *)notification {
    [self setKeyboard];
}


// 根据系统键盘设置view的大小
- (void)setView {
    self.keyView = nil;
    
    self.tempKeyView = (UITextView *)[self getKeyboardView];
    self.keyView.frame = self.tempKeyView.frame;
    self.keyView.backgroundColor = [UIColor grayColor];
    [self.tempKeyView addSubview:self.keyView];
}

- (void)keyboardDidShow {
    self.numberArr = [self setRandomNumber];
    self.letterArr = [self setRandomLetter];
    
    [self setKeyboard];
}

#pragma mark -自定义控件及布局
- (void)setKeyboard {
    [self setView];
    // 键盘每行按键的 行高度keyboardLH、行宽度keyboardLW
    CGFloat keyboardLH = self.keyView.frame.size.height/6.0;
    CGFloat keyboardLW = [UIScreen mainScreen].bounds.size.width;
    
    // 按键的颜色、大小
    UIColor *keyColor = [UIColor whiteColor];
    UIColor *keyTitleHLightedColor = [UIColor grayColor];
    UIColor *keyTitleColor = [UIColor blackColor];
    CGFloat keyWithNumLetterW = (keyboardLW-55)/10.0;
    CGFloat keyWithNumLetterH = keyboardLH - 8.0;
    CGFloat keyWithOtherW = keyboardLW/6.0 - 8.0;
    CGFloat keyWithOtherH = keyboardLH - 8.0;
    
    // 按键圆角半径
    CGFloat keyCornerRadius = 6.0;
    
    // 按键索引值与tag
    NSInteger indexWithNumber = 0;
    NSInteger indexWithLetter = 0;
    NSInteger indexWithOther = 0;
    
    // 第一行
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(5, 4, keyWithOtherW, keyWithOtherH);
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
    [cancelBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
    cancelBtn.backgroundColor = keyColor;
    cancelBtn.layer.cornerRadius = keyCornerRadius;
    cancelBtn.tag = indexWithOther;
    indexWithOther ++;
    [cancelBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.keyView addSubview:cancelBtn];
    
    UIButton *completeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    completeBtn.frame = CGRectMake(keyboardLW-keyWithOtherW-5, 4, keyWithOtherW, keyWithOtherH);
    [completeBtn setTitle:@"完成" forState:UIControlStateNormal];
    [completeBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
    completeBtn.backgroundColor = keyColor;
    completeBtn.layer.cornerRadius = keyCornerRadius;
    completeBtn.tag = indexWithOther;
    indexWithOther ++;
    [completeBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.keyView addSubview:completeBtn];
    
    UILabel *titleLb = [[UILabel alloc]initWithFrame:CGRectMake(keyWithOtherW+10, 4, keyboardLW - (keyWithOtherW*2.0+20), keyWithOtherH)];
    titleLb.text = @"银行安全键盘";
    titleLb.backgroundColor = keyColor;
    titleLb.layer.masksToBounds = YES;
    titleLb.layer.cornerRadius = keyCornerRadius;
    titleLb.textAlignment = NSTextAlignmentCenter;
    [self.keyView addSubview:titleLb];
    
    // 第二行 数字
    for (NSInteger i = 0; i < 10; i ++) {
        UIButton *numberBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        numberBtn.frame = CGRectMake(5+(keyboardLW-55)/10.0*i+5*i, keyboardLH+4, keyWithNumLetterW, keyWithNumLetterH);
        [numberBtn setTitle:self.numberArr[indexWithNumber] forState:UIControlStateNormal];
        numberBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [numberBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
        [numberBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
        numberBtn.backgroundColor = keyColor;
        numberBtn.layer.cornerRadius = keyCornerRadius;
        numberBtn.tag = 100 + indexWithNumber;
        indexWithNumber ++;
        [numberBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.keyView addSubview:numberBtn];
        
    }
    // 第三行 字母
    for (NSInteger i = 0; i < 10; i ++) {
        UIButton *letterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        letterBtn.frame = CGRectMake(5+(keyboardLW-55)/10.0*i+5*i, keyboardLH*2.0+4, keyWithNumLetterW, keyWithNumLetterH);
        [letterBtn setTitle:self.letterArr[indexWithLetter] forState:UIControlStateNormal];
        letterBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [letterBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
        [letterBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
        letterBtn.backgroundColor = keyColor;
        letterBtn.layer.cornerRadius = keyCornerRadius;
        letterBtn.tag = 200 + indexWithLetter;
        indexWithLetter ++;
        [letterBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.keyView addSubview:letterBtn];
    }
    
    // 第四行 字母
    for (NSInteger i = 0; i < 9; i ++) {
        UIButton *letterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        letterBtn.frame = CGRectMake((5+(keyboardLW-55)/10.0*i+5*i)+keyWithNumLetterW/2.0, keyboardLH*3.0+4, keyWithNumLetterW, keyWithNumLetterH);
        [letterBtn setTitle:self.letterArr[indexWithLetter] forState:UIControlStateNormal];
        letterBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [letterBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
        [letterBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
        letterBtn.backgroundColor = keyColor;
        letterBtn.layer.cornerRadius = keyCornerRadius;
        letterBtn.tag = 200 + indexWithLetter;
        indexWithLetter ++;
        [letterBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.keyView addSubview:letterBtn];
        
    }
    
    // 第五行 字母
    for (NSInteger i = 0; i < 7; i ++) {
        UIButton *letterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        letterBtn.frame = CGRectMake((5+(keyboardLW-55)/10.0*i+5*i)+keyWithNumLetterW/2.0+keyWithNumLetterW+5, keyboardLH*4.0+4, keyWithNumLetterW, keyWithNumLetterH);
        [letterBtn setTitle:self.letterArr[indexWithLetter] forState:UIControlStateNormal];
        letterBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [letterBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
        [letterBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
        letterBtn.backgroundColor = keyColor;
        letterBtn.layer.cornerRadius = keyCornerRadius;
        letterBtn.tag = 200 + indexWithLetter;
        indexWithLetter ++;
        [letterBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.keyView addSubview:letterBtn];
        
    }
    
    // 第五行 大小写切换键
    UIButton *switchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    switchBtn.frame = CGRectMake(5, keyboardLH*4.0+4, keyWithNumLetterW/2.0+keyWithNumLetterW, keyWithOtherH);
    
    if (letterState) {
        [switchBtn setTitle:@"大写" forState:UIControlStateNormal];
    }else{
        [switchBtn setTitle:@"小写" forState:UIControlStateNormal];
    }
    switchBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [switchBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
    [switchBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
    switchBtn.backgroundColor = keyColor;
    switchBtn.layer.cornerRadius = keyCornerRadius;
    switchBtn.tag = indexWithOther;
    indexWithOther ++;
    [switchBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.keyView addSubview:switchBtn];
    
    // 第五行 删除键
    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteBtn.frame = CGRectMake(keyboardLW*0.847, keyboardLH*4.0+4, keyWithNumLetterW/2.0+keyWithNumLetterW+5, keyWithOtherH);
    [deleteBtn setTitle:@"delete" forState:UIControlStateNormal];
    deleteBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [deleteBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
    [deleteBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
    deleteBtn.backgroundColor = keyColor;
    deleteBtn.layer.cornerRadius = keyCornerRadius;
    deleteBtn.tag = indexWithOther;
    indexWithOther ++;
    [deleteBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.keyView addSubview:deleteBtn];
    
    // 第六行 纯数字键盘
    UIButton *numberBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    numberBtn.frame = CGRectMake(5, keyboardLH*5.0+4, keyWithNumLetterW/2.0+keyWithNumLetterW, keyWithOtherH);
    [numberBtn setTitle:@".?123" forState:UIControlStateNormal];
    numberBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [numberBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
    [numberBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
    numberBtn.backgroundColor = keyColor;
    numberBtn.layer.cornerRadius = keyCornerRadius;
    numberBtn.tag = indexWithOther;
    indexWithOther ++;
    [numberBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.keyView addSubview:numberBtn];
    
    // 第六行 (全球键)切换系统键盘
    UIButton *globalBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    globalBtn.frame = CGRectMake(keyWithNumLetterW/2.0+keyWithNumLetterW+10, keyboardLH*5.0+4, keyWithNumLetterW+keyWithNumLetterW/2.0, keyWithOtherH);
    [globalBtn setTitle:@"ooo" forState:UIControlStateNormal];
    globalBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [globalBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
    [globalBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
    globalBtn.backgroundColor = keyColor;
    globalBtn.layer.cornerRadius = keyCornerRadius;
    globalBtn.tag = indexWithOther;
    indexWithOther ++;
    
    [globalBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.keyView addSubview:globalBtn];
    
    // 第六行 空格键
    UIButton *spaceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    spaceBtn.frame = CGRectMake(keyWithNumLetterW/2.0+keyWithNumLetterW+10+keyWithNumLetterW+keyWithNumLetterW/2.0+5, keyboardLH*5.0+4, keyWithNumLetterW*5.5+25, keyWithOtherH);
    [spaceBtn setTitle:@"空格" forState:UIControlStateNormal];
    spaceBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [spaceBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
    [spaceBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
    spaceBtn.backgroundColor = keyColor;
    spaceBtn.layer.cornerRadius = keyCornerRadius;
    spaceBtn.tag = indexWithOther;
    indexWithOther ++;
    [spaceBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.keyView addSubview:spaceBtn];
    
    // 第六行 符号键
    UIButton *symbolBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    symbolBtn.frame = CGRectMake(keyboardLW*0.847, keyboardLH*5.0+4, keyWithNumLetterW/2.0+keyWithNumLetterW+5, keyWithOtherH);
    [symbolBtn setTitle:@"#=+" forState:UIControlStateNormal];
    symbolBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [symbolBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
    [symbolBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
    symbolBtn.backgroundColor = keyColor;
    symbolBtn.layer.cornerRadius = keyCornerRadius;
    symbolBtn.tag = indexWithOther;
    [symbolBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.keyView addSubview:symbolBtn];
    
}

// 按钮的点击事件
- (void)clickAction:(UIButton *)sender{
    [sender setHighlighted:YES];
    if (!(sender.tag == 7 || sender.tag == 6 || sender.tag == 5 || sender.tag == 4 || sender.tag == 3 || sender.tag == 2 || sender.tag == 1 || sender.tag == 0)) {
        [self pressedEvent:sender];
        if (self.password == nil) {
            self.password = sender.titleLabel.text;
        }else{
            self.password = [NSString stringWithFormat:@"%@%@", _password, sender.titleLabel.text];
        }
        // block 回调时机
        if (self.passwordBlock != nil ) {
            self.passwordBlock(self.password);
        }
    }
    if (sender.tag == 0) {// 取消事件
        [self.keyView endEditing:YES];
    }
    if (sender.tag == 1) {// 完成事件
        NSLog(@"返回密码：%@", self.password);
    }
    if (sender.tag == 2) {
        if (letterState) {// 大写
            for (NSInteger i = 0; i < 26; i ++) {
                NSString *capitalLetter = [self.letterArr objectAtIndex:i];
                [self.letterArr removeObjectAtIndex:i];
                capitalLetter = [capitalLetter stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[capitalLetter substringToIndex:1] uppercaseString]];
                [self.letterArr insertObject:capitalLetter atIndex:i];
            }
            letterState = 0;
            [self setKeyboard];
        }
        else {// 小写
            for (NSInteger i = 0; i < 26; i ++) {
                NSString *capitalLetter = [self.letterArr objectAtIndex:i];
                [self.letterArr removeObjectAtIndex:i];
                capitalLetter = [capitalLetter stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[capitalLetter substringToIndex:1] lowercaseString]];
                [self.letterArr insertObject:capitalLetter atIndex:i];
            }
            letterState = 1;
            [self setKeyboard];
        }
    }
    if (sender.tag == 3) {// 删除事件
        if ([_password length] != 0) {
            _password = [_password substringToIndex:[_password length] - 1];
            // block 回调时机
            if (self.passwordBlock != nil ) {
                self.passwordBlock(self.password);
            }
        }
    }
    if (sender.tag == 4) {// 纯数字键盘
        
    }
    if (sender.tag == 5) {// 切换系统键盘
//        [self.keyView removeFromSuperview];
    }
    if (sender.tag == 6) {// 空格键
        if (self.password == nil) {
            self.password = @" ";
        }else{
            _password = [NSString stringWithFormat:@"%@%@", _password, @" "];
        }
        // block 回调时机
        if (self.passwordBlock != nil ) {
            self.passwordBlock(self.password);
        }
    }
    if (sender.tag == 7) {// 符号键盘
        
    }
}

- (void)inputModeDidChange:(NSNotification *)notification {
    [self.keyView removeFromSuperview];
    if (switchNum == 2) {
        [self keyboardDidShow];
        switchNum = 0;
    }
    NSLog(@"switchNum:%ld", switchNum);
    switchNum ++;
}


#pragma mark --- 按钮点击放大效果
// 放大按钮
- (void)pressedEvent:(UIButton *)btn
{
    [UIView animateWithDuration:Kduration animations:^{
        btn.transform = CGAffineTransformMakeScale(Kscale, Kscale);
        btn.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        [self cancelEvent:btn];
    }];
}
// 恢复原来状态
- (void)cancelEvent:(UIButton *)btn
{
    [UIView animateWithDuration:Kduration animations:^{
        btn.transform = CGAffineTransformMakeScale(1.0, 1.0);
        btn.backgroundColor = [UIColor whiteColor];
    }];
    
}

#pragma mark ---- 获取键盘的view
- (UIView *)getKeyboardView{
    UIView *keyboardView = nil;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    // 逆序效率更高，因为键盘总在上方
    for (UIWindow *window in [windows reverseObjectEnumerator]){
        keyboardView = [self findKeyboardInView:window];
        if (keyboardView){
            return keyboardView;
        }
    }
    return nil;
}

- (UIView *)findKeyboardInView:(UIView *)view{
    for (UIView *subView in [view subviews]){
        if (strstr(object_getClassName(subView), "UIKeyboard")){
            return subView;
        }
        else{
            UIView *tempView = [self findKeyboardInView:subView];
            if (tempView){
                return tempView;
            }
        }
    }
    return nil;
}


#pragma mark -随机0~9、字母
// 随机数字
- (NSMutableArray *)setRandomNumber {
    NSArray *temp = [NSArray arrayWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", @"6",@"7", @"8",@"9",nil];
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:temp];
    NSInteger count = temp.count;
    NSMutableArray *numberArr = [[NSMutableArray alloc]init];
    for (NSInteger i = 0; i < count; i ++) {
        int index = arc4random() % (count - i);
        [numberArr addObject:[tempArray objectAtIndex:index]];
        [tempArray removeObjectAtIndex:index];
    }
    return numberArr;
}
// 随机字母
- (NSMutableArray *)setRandomLetter {
    NSArray *temp = [NSArray arrayWithObjects:@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z", nil];
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:temp];
    NSInteger count = temp.count;
    NSMutableArray *letterArr = [[NSMutableArray alloc]init];
    for (NSInteger i = 0; i < count; i ++) {
        int index = arc4random() % (count - i);
        [letterArr addObject:[tempArray objectAtIndex:index]];
        [tempArray removeObjectAtIndex:index];
    }
    return letterArr;
}



@end
