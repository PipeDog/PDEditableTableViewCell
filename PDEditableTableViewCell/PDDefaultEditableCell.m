//
//  PDDefaultEditableCell.m
//  PDEditableTableViewCell
//
//  Created by liang on 2020/1/19.
//  Copyright © 2020 liang. All rights reserved.
//

#import "PDDefaultEditableCell.h"
#import <Masonry.h>

@interface PDDefaultEditableCell ()

@property (nonatomic, strong) UILabel *contentLabel;

@end

@implementation PDDefaultEditableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self commitInit];
        [self createViewHierarchy];
        [self layoutContentViews];
    }
    return self;
}

- (void)commitInit {
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.edgeInsets = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
    self.itemsContainerView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2f];
    
    PDEditableCellItemCreator *creator = [[PDEditableCellItemCreator alloc] init];
    [creator createEditableCellItemWithBlock:^__kindof PDEditableCellItem * _Nonnull(NSUInteger index) {
        UIButton *item = [[UIButton alloc] init];
        item.titleLabel.font = [UIFont systemFontOfSize:14];
        if (index == 0) {
            // Set item style 0.
            item.backgroundColor = [UIColor redColor];
            [item setTitle:@"Add" forState:UIControlStateNormal];
        } else if (index == 1) {
            // Set item style 2.
            item.backgroundColor = [UIColor blueColor];
            [item setTitle:@"Del" forState:UIControlStateNormal];
        } else {
            // Set other style.
            item.backgroundColor = [UIColor orangeColor];
            [item setTitle:@"Fix" forState:UIControlStateNormal];
        }
        return item;
    }];
    
    PDEditableCellItemLayouter *layouter = [[PDEditableCellItemLayouter alloc] init];
    layouter.size = CGSizeMake(40.f, 40.f);
    layouter.edgeInsets = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
    
    [self addActions:@[
        [PDEditableCellItemAction actionWithCreator:creator layouter:layouter handler:^{
            NSLog(@"Log Add here...");
        }],
        [PDEditableCellItemAction actionWithCreator:creator layouter:layouter handler:^{
            NSLog(@"Log Delete here...");
        }],
        [PDEditableCellItemAction actionWithCreator:creator layouter:layouter handler:^{
            NSLog(@"Log Fix here...");
        }],
        // Other actions...
    ]];
}

- (void)createViewHierarchy {
    [self.containerView addSubview:self.contentLabel];
}

- (void)layoutContentViews {
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
}

#pragma mark - Public Methods
- (void)setDataSource:(NSString *)dataSource {
    self.contentLabel.text = dataSource ?: @"";
}

#pragma mark - Getter Methods
- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
    }
    return _contentLabel;
}

@end
