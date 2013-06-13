//
//  ZNSettingsViewController.m
//  ZincWallet
//
//  Created by Aaron Voisine on 6/11/13.
//  Copyright (c) 2013 zinc. All rights reserved.
//

#import "ZNSettingsViewController.h"
#import "ZNSeedViewController.h"
#import "ZNWallet.h"

@interface ZNSettingsViewController ()

@property (nonatomic, strong) NSArray *transactions;

@end

@implementation ZNSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.transactions = [ZNWallet sharedInstance].recentTransactions;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction

- (IBAction)done:(id)sender
{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case 0: return self.transactions.count ? self.transactions.count : 1;
        case 1: return 2;
        default:
            NSAssert(FALSE, @"[%s %s] line %d: unkown section %d", object_getClassName(self), sel_getName(_cmd),
                     __LINE__, section);
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *disclosureIdent = @"ZNDisclosureCell", *transactionIdent = @"ZNTransactionCell";
    UITableViewCell *cell = nil;
    
    // Configure the cell...
    switch (indexPath.section) {
        case 0:
            cell = [tableView dequeueReusableCellWithIdentifier:transactionIdent];
            if (! self.transactions.count) {
                cell.textLabel.text = @"no transactions";
                cell.detailTextLabel.text = nil;
            }
            else {
                ZNWallet *w = [ZNWallet sharedInstance];
                NSDictionary *tx = self.transactions[indexPath.row];
                
                BOOL sending = ([tx[@"inputs"] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    return [w containsAddress:obj[@"prev_out"][@"addr"]] ? (*stop = YES) : NO;
                }] != NSNotFound);
               
                __block long long value = 0;
                NSSet *outs = [tx[@"out"] objectsPassingTest:^BOOL(id obj, BOOL *stop) {
                    value += [obj[@"value"] unsignedLongLongValue];
                
                    if (sending) return [w containsAddress:obj[@"addr"]] ? NO : YES;
                    else return [w containsAddress:obj[@"addr"]] ? YES : NO;
                }];
                
                if (! outs.count) {
                    cell.textLabel.text = @"moved within wallet";
                }
                else {
                    NSDictionary *o = outs.anyObject;

                    value = [o[@"value"] longLongValue]*(sending ? -1 : 1);
                    cell.textLabel.text = o[@"addr"];
                }
                
                cell.detailTextLabel.text =
                    [w.format stringFromNumber:@(value/pow(10, w.format.maximumFractionDigits))];
            }
            break;
            
        case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:disclosureIdent];
            
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"safety tips";
                    break;

                case 1:
                    cell.textLabel.text = @"backup phrase";
                    break;
            
                default:
                    NSAssert(FALSE, @"[%s %s] line %d: unkown indexPath.row %d", object_getClassName(self),
                             sel_getName(_cmd), __LINE__, indexPath.row);
            }
            break;
            
        default:
            NSAssert(FALSE, @"[%s %s] line %d: unkown indexPath.section %d", object_getClassName(self),
                     sel_getName(_cmd), __LINE__, indexPath.section);
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return @"recent transactions";
        case 1: return nil;
        default:
            NSAssert(FALSE, @"[%s %s] line %d: unkown section %d", object_getClassName(self), sel_getName(_cmd),
                     __LINE__, section);
    }
    
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.

    //XXX should have some option to generate a new wallet and sweep old balance if backup may be compromized

    switch (indexPath.section) {
        case 0:
            //XXX show transaction details
            break;
            
        case 1:
            switch (indexPath.row) {
                case 0:
                    //XXX show safety tips
                    [[[UIAlertView alloc] initWithTitle:@"SAFETY FIRST!" message:@"Don't eat yellow snow." delegate:nil
                      cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    break;
                    
                case 1:
                    [[[UIAlertView alloc] initWithTitle:@"WARNING" message:@"DO NOT lose your backup phrase.\nWrite it "
                      "down. Lose it and your bitcoins are gone forever.\n\nDO NOT let anyone see your backup phrase "
                      "or they can spend your bitcoins." delegate:self cancelButtonTitle:@"cancel"
                      otherButtonTitles:@"show", nil] show];
                    break;
                    
                default:
                    NSAssert(FALSE, @"[%s %s] line %d: unkown indexPath.row %d", object_getClassName(self),
                             sel_getName(_cmd), __LINE__, indexPath.row);
            }
            break;
            
        default:
            NSAssert(FALSE, @"[%s %s] line %d: unkown indexPath.section %d", object_getClassName(self),
                     sel_getName(_cmd), __LINE__, indexPath.section);
            break;
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) return;
    
    ZNSeedViewController *c = [self.storyboard instantiateViewControllerWithIdentifier:@"ZNSeedViewController"];
    [self.navigationController pushViewController:c animated:YES];
}

@end
