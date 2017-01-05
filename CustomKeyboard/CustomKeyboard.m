//
//  CustomKeyboard.m
//  CustomKeyboard
//
//  Created by liaopeikai on 2016/11/30.
//  Copyright © 2016年 beichende. All rights reserved.
//

#import "CustomKeyboard.h"
//#import "SymbolsCollectionViewCell.h"

//#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
//#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

#define Kscale 3.0       // 按钮放大系数
#define Kduration 0.2    // 动画持续时间

@interface CustomKeyboard ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property(nonatomic, strong) UIInputViewController *inputVC;

@property(nonatomic,strong) NSString *password;

@property(nonatomic,strong) UIView *keyView;
@property(nonatomic,strong) UIView *tempKeyView;
@property(nonatomic, strong) UICollectionView *collectionView;

@property(nonatomic,strong) NSMutableArray *letterArr;
@property(nonatomic,strong) NSMutableArray *numberArr;
@property(nonatomic, strong) NSArray *symbolArray;

@property(nonatomic, strong) PasswordBlock passwordBlock;

@property (nonatomic, assign) NSInteger currentOrient;

@end


@implementation CustomKeyboard
// 大小写状态(默认1:小写)
NSInteger letterState = 1;
// 符号与数字切换（默认1:数字）
NSInteger symbolState = 1;
// 系统键盘弹起通知次数
NSInteger notificationCount = 0;
// 循环切换系统键盘一次后再切换为自定义键盘
NSInteger switchNum = 0;
// 键盘标识，判断是自定义默认键盘时，横竖屏切换才重绘
NSInteger customKeyboardID = 1;
// 纯数字键盘标识，判断是纯数字键盘时，横竖屏切换才重绘
NSInteger numberKeyboardID = 1;

#pragma mark - 懒加载

- (UIInputViewController *)inputVC {
    if (!_inputVC) {
        _inputVC = [[UIInputViewController alloc] init];
    }
    return _inputVC;
}

- (UIView *)keyView {
    if (_keyView == nil) {
        _keyView = [[UIView alloc] init];
    }
    return _keyView;
}

- (UIView *)tempKeyView {
    if (!_tempKeyView) {
        _tempKeyView = [[UIView alloc] init];
    }
    return _tempKeyView;
}


#pragma mark ---- 外部接口
- (void)returnPasswordBlock:(PasswordBlock)block {
    self.passwordBlock = block;
}

- (NSString *)getPassword {
    return self.password;
}
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


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        // 监听键盘弹起通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
        // 监听屏幕旋转通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        // 监听切换输入法通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputModeDidChange:) name:UITextInputCurrentInputModeDidChangeNotification object:nil];
        
        self.currentOrient = [UIApplication  sharedApplication].statusBarOrientation;
        
    }
    return self;
}


#pragma mark ---- 键盘弹起 & 屏幕旋转 & 切换键盘
- (void)keyboardWillShow:(NSNotification *)notification {
    // 系统键盘弹起回调2次，并且系统键盘的切换也会发出键盘弹起通知
    if (switchNum == 1) {
        if (notificationCount == 1 && customKeyboardID == 1) {
            [self.keyView removeFromSuperview];
            [self keyboardDidShow];
        }else {
            [self.keyView removeFromSuperview];
            notificationCount = 1;
        }
        if (numberKeyboardID == 0) {
            [self.keyView removeFromSuperview];
            [self setNumberKeyboard];
        }
    }
}

- (void)orientChange:(NSNotification *)notification {
    UIInterfaceOrientation currentOrient = [UIApplication  sharedApplication].statusBarOrientation;
    if (self.currentOrient != currentOrient && customKeyboardID == 1) {
        self.currentOrient = currentOrient;
        [self.keyView removeFromSuperview];
        [self setKeyboard];
    }
    if (numberKeyboardID == 0) {
        [self.keyView removeFromSuperview];
        [self setNumberKeyboard];
    }
    notificationCount = 1;
}

- (void)inputModeDidChange:(NSNotification *)notification {
    if (switchNum == 4) {
        customKeyboardID = 1;
        switchNum = 0;
    }
    switchNum ++;
}

- (void)clickAction:(UIButton *)sender{
    if (!(sender.tag == 8 || sender.tag == 7 || sender.tag == 6 || sender.tag == 5 || sender.tag == 4 || sender.tag == 3 || sender.tag == 2 || sender.tag == 1 || sender.tag == 0)) {
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
        [self.inputVC dismissKeyboard];
    }
    if (sender.tag == 1) {// 完成事件
        [self.inputVC dismissKeyboard];
    }
    if (sender.tag == 2) {
        if (letterState) {// 大写
            [self.keyView removeFromSuperview];
            [self capitalLetter];
        }
        else {// 小写
            [self.keyView removeFromSuperview];
            [self lowercaseLetter];
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
        numberKeyboardID = 0;
        [self.keyView removeFromSuperview];
        [self setNumberKeyboard];
        
    }
    if (sender.tag == 5) {// 切换系统键盘
        customKeyboardID = 0;
        [self.keyView removeFromSuperview];
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
        if (symbolState) {
            [self.keyView removeFromSuperview];
            symbolState = 0;
            [self setSymbolKeyboard];
        }else {
            [self.keyView removeFromSuperview];
            symbolState = 1;
            [self setKeyboard];
        }
    }
    if (sender.tag == 8) {// 由纯数字键盘返回原来键盘
        [self.keyView removeFromSuperview];
        numberKeyboardID = 1;
        [self setKeyboard];
    }
}

// 小写
- (void)lowercaseLetter {
    for (NSInteger i = 0; i < 26; i ++) {
        NSString *lowercaseLetter = [self.letterArr objectAtIndex:i];
        [self.letterArr removeObjectAtIndex:i];
        lowercaseLetter = [lowercaseLetter stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[lowercaseLetter substringToIndex:1] lowercaseString]];
        [self.letterArr insertObject:lowercaseLetter atIndex:i];
    }
    letterState = 1;
    [self setKeyboard];
}


// 大写
- (void)capitalLetter {
    for (NSInteger i = 0; i < 26; i ++) {
        NSString *capitalLetter = [self.letterArr objectAtIndex:i];
        [self.letterArr removeObjectAtIndex:i];
        capitalLetter = [capitalLetter stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[capitalLetter substringToIndex:1] uppercaseString]];
        [self.letterArr insertObject:capitalLetter atIndex:i];
    }
    letterState = 0;
    [self setKeyboard];
}


// 根据系统键盘设置view的大小
- (void)setView {
    self.keyView = nil;
    
    self.tempKeyView = [self getKeyboardView];
    self.keyView.frame = self.tempKeyView.frame;
    self.keyView.backgroundColor = [UIColor grayColor];
    [self.tempKeyView addSubview:self.keyView];
}

- (void)keyboardDidShow {
    self.numberArr = [self setRandomNumber];
    self.letterArr = [self setRandomLetter];
    
    [self setKeyboard];
}

#pragma mark ---- 自定义控件及布局
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
    
    if (symbolState == 0) { // 符号行
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        flowLayout.itemSize = CGSizeMake(keyWithNumLetterW, keyWithNumLetterH);
        
        CGRect collectionViewFrame = CGRectMake(5, keyboardLH+4, keyboardLW-10, keyWithNumLetterH);
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:collectionViewFrame collectionViewLayout:flowLayout];
        
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.backgroundColor = [UIColor whiteColor];
        
        [self.collectionView registerClass:[SymbolsCollectionViewCell class] forCellWithReuseIdentifier:@"symbolsCell"];
        
        [self.keyView addSubview:self.collectionView];
        
    }else {
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
    [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
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
    [numberBtn setTitle:@"123" forState:UIControlStateNormal];
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
    if (symbolState == 0) {
        symbolBtn.backgroundColor = [UIColor greenColor];
    }
    symbolBtn.layer.cornerRadius = keyCornerRadius;
    symbolBtn.tag = indexWithOther;
    [symbolBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.keyView addSubview:symbolBtn];
    
}

#pragma mark ---- UICollectionView delegate & dataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    self.symbolArray = [self setSymbol];
    return self.symbolArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    SymbolsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"symbolsCell" forIndexPath:indexPath];
    
    cell.symbolsLabel.textColor = [UIColor blackColor];
    cell.symbolsLabel.text = [self.symbolArray objectAtIndex:indexPath.row];
    cell.symbolsLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *symbol = self.symbolArray[indexPath.row];
    if (self.password == nil) {
        self.password = symbol;
    }else{
        self.password = [NSString stringWithFormat:@"%@%@", _password, symbol];
    }
    // block 回调时机
    if (self.passwordBlock != nil ) {
        self.passwordBlock(self.password);
    }
}


#pragma mark ---- 按钮点击放大效果
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


#pragma mark ----- 随机0~9、字母 & 符号
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
// 符号数组
- (NSArray *)setSymbol {
    NSArray *symbolArray = [NSArray arrayWithObjects: @"%", @".",  @"@", @"?", @"+", @"-", @"=", @"_", @"(" , @")", @",", @"*", @"&", @"^", @"$", @"#", @";", @"!", @"`", @"~", @":", @"\"", @"\"",  @"\\",  @"/", @"[", @"]", @"{", @"}", @"|", @"'", @"<", @">", nil];
    return symbolArray;
}


#pragma mark ---- 纯数字键盘 & 符号键盘
- (void)setSymbolKeyboard {
    [self setKeyboard];
}
- (void)setNumberKeyboard {
    [self setView];
    // 键盘每行按键的 行高度keyboardLH、行宽度keyboardLW
    CGFloat firstKeyboardLH = self.keyView.frame.size.height/6.0;
    CGFloat keyboardLH = (self.keyView.frame.size.height - firstKeyboardLH)/4.0;
    CGFloat keyboardLW = [UIScreen mainScreen].bounds.size.width;
    
    // 按键的颜色、大小
    UIColor *keyColor = [UIColor whiteColor];
    UIColor *keyTitleHLightedColor = [UIColor grayColor];
    UIColor *keyTitleColor = [UIColor blackColor];
    
    CGFloat keyWithNumLetterW = (keyboardLW - 8.0) / 3.0;
    CGFloat keyWithNumLetterH = keyboardLH - 2.0;
    CGFloat keyWithOtherW = keyboardLW/6.0;
    CGFloat keyWithOtherH = firstKeyboardLH;
    
    // 按键索引值与tag
    NSInteger indexWithNumber = 0;
    NSInteger indexWithOther = 0;
    
    // 第一行
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(3, 1, keyWithOtherW, keyWithOtherH);
    [cancelBtn setTitle:@"返回" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
    [cancelBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
    cancelBtn.backgroundColor = keyColor;
    cancelBtn.tag = 8;
    [cancelBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.keyView addSubview:cancelBtn];
    
    UIButton *completeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    completeBtn.frame = CGRectMake(keyboardLW - keyWithOtherW - 3, 1, keyWithOtherW, keyWithOtherH);
    [completeBtn setTitle:@"完成" forState:UIControlStateNormal];
    [completeBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
    completeBtn.backgroundColor = keyColor;
    completeBtn.tag = indexWithOther + 1;
    indexWithOther ++;
    [completeBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.keyView addSubview:completeBtn];
    
    UILabel *titleLb = [[UILabel alloc]initWithFrame:CGRectMake(keyWithOtherW + 4, 1, keyboardLW - (keyWithOtherW * 2.0 + 8), keyWithOtherH)];
    titleLb.text = @"银行安全键盘";
    titleLb.backgroundColor = keyColor;
    titleLb.textColor = keyTitleColor;
    titleLb.layer.masksToBounds = YES;
    titleLb.textAlignment = NSTextAlignmentCenter;
    [self.keyView addSubview:titleLb];
    
    
    for (NSInteger j = 0; j < 4; j ++) {
        for (NSInteger i = 0; i < 3; i ++) {
            if (j == 3 && (i == 0 || i == 2)) {
                UIButton *numberBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                numberBtn.frame = CGRectMake(3+(keyWithNumLetterW+1)*i, (keyWithOtherH+2)+(keyWithNumLetterH+1)*j, keyWithNumLetterW, keyWithNumLetterH);
                if (i == 0) {
                    [numberBtn setTitle:@"." forState:UIControlStateNormal];
                    indexWithOther = 100 + 11; // 0~9 加上 .
                } else {
                    [numberBtn setTitle:@"删除" forState:UIControlStateNormal];
                    indexWithOther = 3;
                }
                numberBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
                [numberBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
                [numberBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
                numberBtn.backgroundColor = keyColor;
                numberBtn.tag = indexWithOther;
                [numberBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
                
                [self.keyView addSubview:numberBtn];
                
            } else {
                UIButton *numberBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                if (j == 0) {
                    numberBtn.frame = CGRectMake(3+(keyWithNumLetterW+1)*i, (keyWithOtherH+2), keyWithNumLetterW, keyWithNumLetterH);
                }else {
                    numberBtn.frame = CGRectMake(3+(keyWithNumLetterW+1)*i, (keyWithOtherH+2)+(keyWithNumLetterH+1)*j, keyWithNumLetterW, keyWithNumLetterH);
                }
                [numberBtn setTitle:self.numberArr[indexWithNumber] forState:UIControlStateNormal];
                numberBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
                [numberBtn setTitleColor:keyTitleColor forState:UIControlStateNormal];
                [numberBtn setTitleColor:keyTitleHLightedColor forState:UIControlStateHighlighted];
                numberBtn.backgroundColor = keyColor;
                numberBtn.tag = 100 + indexWithNumber;
                indexWithNumber ++;
                [numberBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
                
                [self.keyView addSubview:numberBtn];
            }
            
        }
    }
}

@end

@implementation SymbolsCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _symbolsLabel = [[UILabel alloc] init];
        _symbolsLabel.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [self addSubview:_symbolsLabel];
        
    }
    return self;
}
@end

