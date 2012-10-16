//
//  ContactsViewController.h
//  BasicPhone
//
//  Created by Efim Polevoi on 10/14/12.
//
//

#import <UIKit/UIKit.h>

@interface ContactsViewController : UITableViewController <UITableViewDataSource> {
    UITableView *ContactsTableView;
}
@property (retain, nonatomic) IBOutlet UITableView *ContactsTableView;

@end
