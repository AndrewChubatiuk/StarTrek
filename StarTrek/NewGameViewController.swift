//
//  MCScene.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 4/28/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import UIKit

class NewGameViewController: UIViewController, UIPageViewControllerDataSource
{
    var pageViewController : UIPageViewController?
    var appDelegate:AppDelegate!
    var currentIndex : Int = 0
    var species : [[String:String]]!
    var server = true
    var choice: Int!
    
    @IBOutlet var pageView: UIView!
    
    override func viewDidLoad()
    {
        readFromPlist()
        super.viewDidLoad()
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pageViewController!.dataSource = self
        let startingViewController: SpaceshipView = viewControllerAtIndex(0)!
        let viewControllers = [startingViewController]
        pageViewController!.setViewControllers(viewControllers , direction: .Forward, animated: false, completion: nil)
        pageViewController!.view.frame = CGRectMake(pageView.frame.minX, 0, pageView.frame.width, pageView.frame.height);
        addChildViewController(pageViewController!)
        pageView.addSubview(pageViewController!.view)
        pageViewController!.didMoveToParentViewController(self)
        //self.pageView
    }
    
    @IBAction func previousView(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destViewController: ConnectionsListController = segue.destinationViewController as! ConnectionsListController
        destViewController.server = self.server
        self.appDelegate.species = self.species[choice]["name"]
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func readFromPlist() {
        self.species = [[String:String]]()
        let path = NSBundle.mainBundle().pathForResource("Species", ofType: "plist")
        let species_array: Array<AnyObject> = (NSArray(contentsOfFile: path!)! as? Array<AnyObject>)!
        for specie_ns in species_array {
            let specie = specie_ns as! NSDictionary
            var specie_dict = [String:String]()
            specie_dict.updateValue((specie.objectForKey("name") as? String)!, forKey: "name")
            specie_dict.updateValue((specie.objectForKey("ship_image") as? String)!, forKey: "ship_image")
            specie_dict.updateValue((specie.objectForKey("base_image") as? String)!, forKey: "base_image")
            specie_dict.updateValue((specie.objectForKey("info") as? String)!, forKey: "info")
            self.species.append(specie_dict)
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    {
        var index = (viewController as! SpaceshipView).pageIndex
        
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index -= 1
        
        return viewControllerAtIndex(index)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
    {
        var index = (viewController as! SpaceshipView).pageIndex
        if index == NSNotFound {
            return nil
        }
        index += 1
        if (index == self.species.count) {
            return nil
        }
        return viewControllerAtIndex(index)
    }
    
    func viewControllerAtIndex(index: Int) -> SpaceshipView?
    {
        if self.species.count == 0 || index >= self.species.count
        {
            return nil
        }
        let pageContentViewController = storyboard!.instantiateViewControllerWithIdentifier("SpaceshipViewController") as! SpaceshipView
        pageContentViewController.speciesShipImageText = species[index]["ship_image"]!
        pageContentViewController.speciesNameText = species[index]["name"]!
        pageContentViewController.speciesInfoText = species[index]["info"]!
        pageContentViewController.pageIndex = index
        currentIndex = index
        choice = index
        return pageContentViewController
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int
    {
        return self.species.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int
    {
        return 0
    }
    
}