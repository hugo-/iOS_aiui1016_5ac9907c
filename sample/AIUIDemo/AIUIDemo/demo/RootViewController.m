//
//  RootViewController.m
//  AIUIDemo
//  Created on: 2018年1月1日
//      Author: 讯飞开放平台（http://aiui.xfyun.cn）
//

#import "RootViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PopupView.h"

@implementation RootViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ( IOS7_OR_LATER )
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
        self.navigationController.navigationBar.translucent = NO;
    }
#endif
    _tbView.delegate = self;
    _tbView.dataSource = self;
    _tbView.separatorColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3];
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = NSLocalizedString(@"pageBack", nil);
    temporaryBarButtonItem.target = self;
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        CGSize size = [UIScreen mainScreen].bounds.size;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, 0.5)];
        view.backgroundColor = [UIColor blackColor];
        return  view;
    }else {
        return nil;
    }
}

@end
