//
//  ViewController.h
//  CustomKeyboard
//
//  Created by liaopeikai on 2016/10/27.
//  Copyright © 2016年 beichende. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

// 获取密码
@property(nonatomic,strong)NSString *password;
- (NSString *)getPassword;

@end

