//
//  CoffeeListTableViewController.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "CoffeeListTableViewController.h"
#import "CoffeeType.h"
#import "CoffeeViewController.h"

@interface CoffeeListTableViewController ()
@property (nonatomic, strong, readonly) NSArray *coffeeList;
@end

@implementation CoffeeListTableViewController

- (void)setSearchTerm:(NSString *)searchTerm {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initializeCoffees];
    
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchBar.placeholder = @"Search";
    searchController.delegate = self;
    searchController.searchResultsUpdater = self;
    self.navigationItem.searchController = searchController;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.coffeeList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"coffeeCell" forIndexPath:indexPath];

    CoffeeType *coffee = self.coffeeList[indexPath.row];
    cell.textLabel.text = coffee.name;
    cell.imageView.image = coffee.image;
    
    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    if (indexPath != nil) {
        CoffeeViewController *coffeeVC = (CoffeeViewController *) segue.destinationViewController;
        if (coffeeVC != nil) {
            coffeeVC.coffeeType = self.coffeeList[indexPath.row];
        }
    }
}

#pragma mark - UISearchControllerDelegate
- (void)willDismissSearchController:(UISearchController *)searchController {
    self.searchTerm = nil;
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *text = searchController.searchBar.text;
    if (text != nil && text.length > 0) {
        filtering = true;
        filteredCoffees = [coffees filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name contains[c] %@", text]];
    } else {
        filtering = false;
    }
    [self.tableView reloadData];
}

#pragma mark - private
UISearchController *searchController;
bool filtering = false;

NSArray *coffees;
NSArray *filteredCoffees;

- (void) initializeCoffees {
    CoffeeType *cappuccino = [[CoffeeType alloc] initWithName:@"Cappuccino" andImage: [UIImage imageNamed:@"Cappuccino"]];
    CoffeeType *latte = [[CoffeeType alloc] initWithName:@"Latte" andImage: [UIImage imageNamed:@"Latte"]];
    CoffeeType *mocha = [[CoffeeType alloc] initWithName:@"Mocha" andImage: [UIImage imageNamed:@"Mocha"]];
    CoffeeType *black = [[CoffeeType alloc] initWithName:@"Black" andImage: [UIImage imageNamed:@"Black"]];

    coffees = @[cappuccino, latte, mocha, black];
    
    filteredCoffees = @[];
}

- (NSArray *) coffeeList {
    return filtering ? filteredCoffees : coffees;
}

@end
