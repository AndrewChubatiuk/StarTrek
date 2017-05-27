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
    var choice: Int = 0
    
    @IBOutlet var pageView: UIView!
    
    override func viewDidLoad()
    {
        readFromPlist()
        super.viewDidLoad()
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController!.dataSource = self
        let startingViewController: SpaceshipView = viewControllerAtIndex(0)!
        let viewControllers = [startingViewController]
        pageViewController!.setViewControllers(viewControllers , direction: .forward, animated: false, completion: nil)
        pageViewController!.view.frame = CGRect(x: pageView.frame.minX, y: 0, width: pageView.frame.width, height: pageView.frame.height);
        addChildViewController(pageViewController!)
        pageView.addSubview(pageViewController!.view)
        pageViewController!.didMove(toParentViewController: self)
    }
    
    @IBAction func previousView(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destViewController: ConnectionsListController = segue.destination as! ConnectionsListController
        self.appDelegate.getMyPlayer()!.setupSpecies(self.species[choice]["name"]!)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func readFromPlist() {
        self.species = [[String:String]]()
        let path = Bundle.main.path(forResource: "Species", ofType: "plist")
        let species_array: Array<AnyObject> = (NSArray(contentsOfFile: path!)! as? Array<AnyObject>)!
        for specie_ns in species_array {
            let specie = specie_ns as! NSDictionary
            var specie_dict = [String:String]()
            specie_dict.updateValue((specie.object(forKey: "name") as? String)!, forKey: "name")
            specie_dict.updateValue((specie.object(forKey: "ship_image") as? String)!, forKey: "ship_image")
            specie_dict.updateValue((specie.object(forKey: "base_image") as? String)!, forKey: "base_image")
            specie_dict.updateValue((specie.object(forKey: "info") as? String)!, forKey: "info")
            self.species.append(specie_dict)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        var index = (viewController as! SpaceshipView).pageIndex
        
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index -= 1
        
        return viewControllerAtIndex(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
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
    
    func viewControllerAtIndex(_ index: Int) -> SpaceshipView?
    {
        if self.species.count == 0 || index >= self.species.count
        {
            return nil
        }
        let pageContentViewController = storyboard!.instantiateViewController(withIdentifier: "SpaceshipViewController") as! SpaceshipView
        pageContentViewController.speciesShipImageText = species[index]["ship_image"]!
        pageContentViewController.speciesNameText = species[index]["name"]!
        pageContentViewController.speciesInfoText = species[index]["info"]!
        pageContentViewController.pageIndex = index
        currentIndex = index
        choice = index
        return pageContentViewController
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int
    {
        return self.species.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int
    {
        return 0
    }
    
}
