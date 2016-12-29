//
//  ViewController.m
//  CustomKeyboard
//
//  Created by liaopeikai on 2016/10/27.
//  Copyright © 2016年 beichende. All rights reserved.
//

#import "ViewController.h"
#import "CustomKeyboard.h"

@interface ViewController ()

@property(nonatomic,strong) UITextField *textFiled1;
@property(nonatomic,strong) UITextField *textFiled2;
@property(nonatomic, strong) CustomKeyboard *customKeyboard;

@end

@implementation ViewController

#pragma mark - 懒加载
- (UITextField *)textFiled1 {
    if (_textFiled1 == nil) {
        _textFiled1 =[[UITextField alloc]initWithFrame:CGRectMake(30, 50, 320, 40)];
        _textFiled1.layer.borderWidth = 1.0f;
        _textFiled1.layer.cornerRadius = 5;
        _textFiled1.layer.borderColor = [UIColor colorWithRed:14/255.0 green:174/255.0 blue:131/255.0 alpha:1].CGColor;
        _textFiled1.placeholder = @"请输入密码";
    }
    return _textFiled1;
}

- (UITextField *)textFiled2 {
    if (_textFiled2 == nil) {
        _textFiled2 =[[UITextField alloc]initWithFrame:CGRectMake(30, 120, 220, 40)];
        _textFiled2.layer.borderWidth = 1.0f;
        _textFiled2.layer.cornerRadius = 5;
        _textFiled2.enabled = NO;
        _textFiled2.layer.borderColor = [UIColor colorWithRed:14/255.0 green:174/255.0 blue:131/255.0 alpha:1].CGColor;
        _textFiled2.placeholder = @"点击右侧按钮";
    }
    return _textFiled2;
}

- (CustomKeyboard *)customKeyboard {
    if (!_customKeyboard) {
        _customKeyboard = [CustomKeyboard shareInstance];
    }
    return _customKeyboard;
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.view addSubview:self.textFiled1];
    [self.view addSubview:self.textFiled2];
    
    [self.customKeyboard returnPasswordBlock:^(id password) {
        self.textFiled1.text = password;
    }];
    
    UIButton *passwordBtn = [UIButton buttonWithType:0];
    passwordBtn.frame = CGRectMake(260, 126, 90, 30);
    passwordBtn.backgroundColor = [UIColor grayColor];
    [passwordBtn setTitle:@"获取密码" forState:0];
    passwordBtn.layer.cornerRadius = 8.0;
    [passwordBtn addTarget:self action:@selector(getPassword) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:passwordBtn];
}

// 隐藏键盘
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.textFiled1 resignFirstResponder];
}

// 获取密码串
- (void)getPassword {
    self.textFiled2.text = [self.customKeyboard getPassword];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
