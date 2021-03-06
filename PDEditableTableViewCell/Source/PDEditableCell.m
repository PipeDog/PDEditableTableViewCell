//
//  PDEditableCell.m
//  PDEditableCell
//
//  Created by liang on 2020/1/19.
//  Copyright © 2020 liang. All rights reserved.
//

#import "PDEditableCell.h"
#import <Masonry/Masonry.h>
#import "UIControl+Block.h"

// Public const value.
CGFloat const PDEditableCellItemFillHeight = CGFLOAT_MAX;

// Private const value.
static CGFloat const kEditableCellItemAnimationDuration = 0.3f;

@implementation PDEditableCellItemAction {
    @public
    PDEditableCellItemCreator *_creator;
    PDEditableCellItemLayouter *_layouter;
    void (^_handler)(void);
}

+ (instancetype)actionWithCreator:(PDEditableCellItemCreator *)creator
                         layouter:(PDEditableCellItemLayouter *)layouter
                          handler:(void (^)(void))handler {
    NSAssert(creator, @"The argument `creator` can not be nil!");
    NSAssert(layouter, @"The argument `layouter` can not be nil!");

    PDEditableCellItemAction *action = [[PDEditableCellItemAction alloc] init];
    action->_creator = creator;
    action->_layouter = layouter;
    action->_handler = handler;
    return action;
}

@end

@implementation PDEditableCellItemCreator {
    @public
    __kindof PDEditableCellItem * (^_createEditableCellItemBlock)(NSUInteger);
}

+ (instancetype)creatorWithBlock:(__kindof PDEditableCellItem * _Nonnull (^)(void))block {
    NSAssert(block, @"The argument `block` can not be nil!");

    PDEditableCellItemCreator *creator = [[PDEditableCellItemCreator alloc] init];
    creator->_createEditableCellItemBlock = [block copy];
    return creator;
}

@end

@implementation PDEditableCellItemLayouter {
    @public
    CGSize _size;
    UIEdgeInsets _edgeInsets;
}

+ (instancetype)layouterWithSize:(CGSize)size edgeInsets:(UIEdgeInsets)edgeInsets {
    PDEditableCellItemLayouter *layouter = [[PDEditableCellItemLayouter alloc] init];
    layouter->_size = size;
    layouter->_edgeInsets = edgeInsets;
    return layouter;
}

@end

@interface PDEditableCell () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *itemsContainerView;
@property (nonatomic, strong) NSMutableArray<PDEditableCellItemAction *> *holder;
@property (nonatomic, assign) BOOL inEditing; // If YES, become edit, else resign edit.
@property (nonatomic, strong) NSMutableArray<PDEditableCellItem *> *items;
@property (nonatomic, assign) CGFloat itemsWidth;
@property (nonatomic, strong) UIPanGestureRecognizer *pan;

@end

@implementation PDEditableCell

@synthesize containerView = _containerView;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self _commitInit];
        [self _createViewHierarchy];
        [self _layoutContentViews];
    }
    return self;
}

- (void)_commitInit {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _edgeInsets = UIEdgeInsetsZero;
    self.editEnabled = YES;
}

- (void)_createViewHierarchy {
    [self.contentView addSubview:self.itemsContainerView];
    [self.contentView addSubview:self.containerView];
}

- (void)_layoutContentViews {
    [self.itemsContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.edgeInsets.top);
        make.left.mas_equalTo(self.edgeInsets.left);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-self.edgeInsets.bottom);
        make.right.equalTo(self.contentView.mas_right).offset(-self.edgeInsets.right);
    }];
    
    [self.containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.edgeInsets.top);
        make.left.mas_equalTo(self.edgeInsets.left);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-self.edgeInsets.bottom);
        make.right.equalTo(self.contentView.mas_right).offset(-self.edgeInsets.right);
    }];
}

#pragma mark - Public Methods
- (void)addActions:(NSArray<PDEditableCellItemAction *> *)actions {
    NSAssert(!self.inEditing, @"Can not add action when become editing state!");

    if (!actions.count) { return; }
    
    [self.holder addObjectsFromArray:actions];
    [self _updateItemsLayoutConstraints];
}

- (void)becomeEditingWithAnimated:(BOOL)animated {
    if (!self.editEnabled) { return; }

    // Define blocks.
    void (^frameBlock)(void) = ^{
        [self _setLeft:(self.edgeInsets.left - self.itemsWidth) forView:self.containerView];
    };
    
    void (^layoutBlock)(void) = ^{
        [self.containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.edgeInsets.top);
            make.left.mas_equalTo((self.edgeInsets.left - self.itemsWidth));
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-self.edgeInsets.bottom);
            make.right.equalTo(self.contentView.mas_right).offset(-self.edgeInsets.right - self.itemsWidth);
        }];
    };
    
    void (^willBecomeEditingBlock)(void) = ^{
        if ([self.delegate respondsToSelector:@selector(willBecomeEditingInCell:)]) {
            [self.delegate willBecomeEditingInCell:self];
        }
    };
    
    void (^didBecomeEditingBlock)(void) = ^{
        if ([self.delegate respondsToSelector:@selector(didBecomeEditingInCell:)]) {
            [self.delegate didBecomeEditingInCell:self];
        }
    };
    
    // Execute actions.
    self.inEditing = YES;
    willBecomeEditingBlock();
    
    if (animated) {
        CGFloat move = fabs(self.edgeInsets.left - CGRectGetMinX(self.containerView.frame));
        NSTimeInterval duration = ((self.itemsWidth - move) / self.itemsWidth) * kEditableCellItemAnimationDuration;
        
        [UIView animateWithDuration:duration animations:^{
            frameBlock();
        } completion:^(BOOL finished) {
            layoutBlock();
            didBecomeEditingBlock();
        }];
    } else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        frameBlock();
        [CATransaction commit];
        
        layoutBlock();
        didBecomeEditingBlock();
    }
}

- (void)resignEditingWithAnimated:(BOOL)animated {
    if (!self.editEnabled) { return; }
    
    [self.contentView resignFirstResponder];
    
    // Define blocks.
    void (^frameBlock)(void) = ^{
        [self _setLeft:self.edgeInsets.left forView:self.containerView];
    };
    
    void (^layoutBlock)(void) = ^{
        [self.containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.edgeInsets.top);
            make.left.mas_equalTo(self.edgeInsets.left);
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-self.edgeInsets.bottom);
            make.right.equalTo(self.contentView.mas_right).offset(-self.edgeInsets.right);
        }];
    };
    
    void (^willResignEditingBlock)(void) = ^{
        if ([self.delegate respondsToSelector:@selector(willResignEditingInCell:)]) {
            [self.delegate willResignEditingInCell:self];
        }
    };
    
    void (^didResignEditingBlock)(void) = ^{
        if ([self.delegate respondsToSelector:@selector(didResignEditingInCell:)]) {
            [self.delegate didResignEditingInCell:self];
        }
    };
    
    // Execute actions.
    self.inEditing = NO;
    willResignEditingBlock();

    if (animated) {
        CGFloat move = fabs(self.edgeInsets.left - CGRectGetMinX(self.containerView.frame));
        NSTimeInterval duration = (move / self.itemsWidth) * kEditableCellItemAnimationDuration;

        [UIView animateWithDuration:duration animations:^{
            frameBlock();
        } completion:^(BOOL finished) {
            layoutBlock();
            didResignEditingBlock();
        }];
    } else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        frameBlock();
        [CATransaction commit];
        
        layoutBlock();
        didResignEditingBlock();
    }
}

#pragma mark - Tool Methods
- (void)_updateItemsLayoutConstraints {
    if (!self.holder.count) { return; }
    
    PDEditableCellItemAction   *previousAction,   *currentAction;
    PDEditableCellItemLayouter *previousLayouter, *currentLayouter;
    PDEditableCellItem         *previousItem,     *currentItem; // Be created by creator.
    
    for (NSUInteger i = 0; i < self.holder.count; i++) {
        currentAction   = self.holder[i];
        currentLayouter = currentAction->_layouter;
        currentItem     = currentAction->_creator->_createEditableCellItemBlock(i);

        [currentItem removeActionsForControlEvents:UIControlEventTouchUpInside];
        [currentItem addActionForControlEvents:UIControlEventTouchUpInside usingBlock:^(__kindof UIControl * _Nonnull control) {
            !currentAction->_handler ?: currentAction->_handler();
        }];

        self.itemsWidth += (currentLayouter->_edgeInsets.left +
                            currentLayouter->_size.width +
                            currentLayouter->_edgeInsets.right);
        [self.itemsContainerView addSubview:currentItem];
        
        [currentItem mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(currentLayouter->_size.width);

            if (currentLayouter->_size.height == PDEditableCellItemFillHeight) {
                make.height.equalTo(self.itemsContainerView.mas_height);
            } else {
                make.height.mas_equalTo(currentLayouter->_size.height);
            }

            make.top.mas_equalTo(currentLayouter->_edgeInsets.top);
            
            if (previousItem) {
                CGFloat itemSpacing = currentLayouter->_edgeInsets.right + previousLayouter->_edgeInsets.left;
                make.right.equalTo(previousItem.mas_left).offset(-itemSpacing);
            } else {
                make.right.equalTo(self.itemsContainerView.mas_right).offset(-currentLayouter->_edgeInsets.right);
            }
        }];

        previousAction   = currentAction;
        previousLayouter = currentLayouter;
        previousItem     = currentItem;
    }
}

- (BOOL)_shouldRespondPanGestureWithOffset:(CGPoint)offset {
    CGFloat x = fabs(offset.x);
    return (x >= 10.f) && (fabs(offset.x) > 3 * fabs(offset.y));
}

- (void)_setLeft:(CGFloat)left forView:(UIView *)aView {
    aView.frame = CGRectMake(left, CGRectGetMinY(aView.frame), CGRectGetWidth(aView.frame), CGRectGetHeight(aView.frame));
}

#pragma mark - Gesture Methods
- (void)_receivePanGesture:(UIPanGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            [self _panGestureRecognizerBegan:sender];
        } break;
        case UIGestureRecognizerStateChanged: {
            [self _panGestureRecognizerChanged:sender];
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            [self _panGestureRecognizerEnded:sender];
        } break;
        default: break;
    }
}

- (void)_panGestureRecognizerBegan:(UIPanGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(panGestureRecognizerStateBeginInEditableCell:)]) {
        [self.delegate panGestureRecognizerStateBeginInEditableCell:self];
    }
}

- (void)_panGestureRecognizerChanged:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender translationInView:self.contentView];
    if (![self _shouldRespondPanGestureWithOffset:point]) {
        return;
    }

    CGFloat originLeft = self.inEditing ? (self.edgeInsets.left - self.itemsWidth) : self.edgeInsets.left;
    CGFloat currentLeft = originLeft + point.x;
    
    if (currentLeft > self.edgeInsets.left) {
        [self _setLeft:self.edgeInsets.left forView:self.containerView];
    } else if (currentLeft < self.edgeInsets.left - self.itemsWidth) {
        [self _setLeft:(self.edgeInsets.left - self.itemsWidth) forView:self.containerView];
    } else {
        [self _setLeft:currentLeft forView:self.containerView];
    }
    
    if ([self.delegate respondsToSelector:@selector(panGestureRecognizerStateChangedInEditableCell:)]) {
        [self.delegate panGestureRecognizerStateChangedInEditableCell:self];
    }
}

- (void)_panGestureRecognizerEnded:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender translationInView:self];
    
    if (self.inEditing && point.x > 0) {
        [self _shouldRespondPanGestureWithOffset:point] ? [self resignEditingWithAnimated:YES] : [self becomeEditingWithAnimated:YES];
    } else if (!self.inEditing && point.x < 0) {
        [self _shouldRespondPanGestureWithOffset:point] ? [self becomeEditingWithAnimated:YES] : [self resignEditingWithAnimated:YES];
    }
    
    if ([self.delegate respondsToSelector:@selector(panGestureRecognizerStateEndedInEditableCell:)]) {
        [self.delegate panGestureRecognizerStateEndedInEditableCell:self];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.pan == otherGestureRecognizer) {
        CGPoint point = [self.pan translationInView:self];
        if ([self _shouldRespondPanGestureWithOffset:point]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Setter Methods
- (void)setEditEnabled:(BOOL)editEnabled {
    _editEnabled = editEnabled;
    
    if (_editEnabled) {
        [self.contentView addGestureRecognizer:self.pan];
        self.itemsContainerView.hidden = NO;
    } else {
        [self.contentView removeGestureRecognizer:self.pan];
        self.itemsContainerView.hidden = YES;
    }
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets {
    _edgeInsets = edgeInsets;
    [self _layoutContentViews];
}

#pragma mark - Getter Methods
- (NSMutableArray<PDEditableCellItemAction *> *)holder {
    if (!_holder) {
        _holder = [NSMutableArray array];
    }
    return _holder;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor whiteColor];
    }
    return _containerView;
}

- (UIView *)itemsContainerView {
    if (!_itemsContainerView) {
        _itemsContainerView = [[UIView alloc] init];
        _itemsContainerView.backgroundColor = [UIColor whiteColor];
        _itemsContainerView.clipsToBounds = YES;
    }
    return _itemsContainerView;
}

- (NSMutableArray<PDEditableCellItem *> *)items {
    if (!_items) {
        _items = [NSMutableArray array];
    }
    return _items;
}

- (UIPanGestureRecognizer *)pan {
    if (!_pan) {
        _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_receivePanGesture:)];
        _pan.delegate = self;
    }
    return _pan;
}

- (NSArray<PDEditableCellItemAction *> *)actions {
    return [self.holder copy];
}

@end
