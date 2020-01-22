//
//  PDDemoEditableCell.m
//  PDEditableTableViewCell
//
//  Created by liang on 2020/1/19.
//  Copyright © 2020 liang. All rights reserved.
//

#import "PDDemoEditableCell.h"
#import <Masonry.h>

@interface PDDemoEditableCell ()

@property (nonatomic, strong) UILabel *contentLabel;

@end

@implementation PDDemoEditableCell

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

    PDEditableCellItemLayouter *layouter = [PDEditableCellItemLayouter layouterWithSize:CGSizeMake(40.f, 40.f) edgeInsets:UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f)];
    
    [self addActions:@[
        [PDEditableCellItemAction actionWithCreator:[self creatorAtIndex:0] layouter:layouter handler:^{
            NSLog(@"Log Add here...");
        }],
        [PDEditableCellItemAction actionWithCreator:[self creatorAtIndex:1] layouter:layouter handler:^{
            NSLog(@"Log Delete here...");
        }],
        [PDEditableCellItemAction actionWithCreator:[self creatorAtIndex:2] layouter:layouter handler:^{
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

#pragma mark - Tool Methods
- (PDEditableCellItemCreator *)creatorAtIndex:(NSInteger)index {
    return [PDEditableCellItemCreator creatorWithBlock:^__kindof PDEditableCellItem * _Nonnull{
        UIButton *item = [UIButton buttonWithType:UIButtonTypeCustom];
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
