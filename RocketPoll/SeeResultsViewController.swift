//
//  SeeResultsViewController.swift
//  SocialPolling
//
//  Created by Igor Kantor on 12/19/14.
//  Copyright (c) 2014 Igor Kantor. All rights reserved.
//

import UIKit
import CoreData

class SeeResultsViewController: PollingViewControllerBase,
    UITableViewDelegate,
    UITableViewDataSource {
//    var responseCounts: NSDictionary = NSDictionary()
    var questionsWithResponseCounts: NSDictionary = NSDictionary()

    let cellIdentifier = "questionResponse"

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        getResponseData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        getResponseData()
    }

    func getResponseData(){

//        var createdByQuery = PFQuery(className: "Answer")
//        createdByQuery.whereKey("answeredBy", equalTo: PFUser.currentUser())
//
//        var myQuestions = PFQuery(className: "Question")
//        myQuestions.whereKey("askedBy", equalTo: PFUser.currentUser())
//
//        var askedByQuery = PFQuery(className: "Answer")
//        askedByQuery.whereKey("question", matchesQuery: myQuestions)
//
//        var query = PFQuery.orQueryWithSubqueries([createdByQuery, askedByQuery])
//        query.includeKey("question")

        var query = PFQuery(className: "Answer")
        query.includeKey("question")

        query.findObjectsInBackgroundWithBlock { (answers, error) -> Void in
            if error == nil {
                // group by the answers and make a dict
                var responseCounts =  Dictionary<String, Dictionary<String, Int>>()

                for answer in answers as [Answer]{
                    if responseCounts[answer.question.text] == nil {
                        var qdict = Dictionary<String, Int>()
                        qdict[answer.selection] = 1
                        responseCounts[answer.question.text] = qdict
                    }
                    else {
                        var qdict = responseCounts[answer.question.text]!
                        if qdict[answer.selection] != nil{
                            let count = qdict[answer.selection]! + 1
                            qdict[answer.selection] = count
                        }
                        else {
                            qdict[answer.selection] = 1
                        }
                        responseCounts[answer.question.text] = qdict
                    }
                }

                self.questionsWithResponseCounts = responseCounts
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.tableView.reloadData()
                })
            }
            else {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    UIAlertView(title: "Error", message: error.description, delegate: nil, cancelButtonTitle: "OK").show()
                })
            }

        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier) as ResponseCountCell
        cell.backgroundColor = UIColor.clearColor()

        // can this code be simplified?
        let questionKey = questionsWithResponseCounts.allKeys[indexPath.section] as String
        let responses = questionsWithResponseCounts[questionKey] as NSDictionary
        let responsesKey = responses.allKeys[indexPath.row] as String
        let responsesValue = responses[responsesKey] as CGFloat

        cell.responseLabel.text = "\(responsesKey) (\(Int(responsesValue)))"
        cell.responseLabel.font = UIFont(name: "Chalkboard SE", size: 10 + responsesValue)

        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = questionsWithResponseCounts.allKeys[section] as String
        let responses = questionsWithResponseCounts[key] as NSDictionary
        return responses.count
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return questionsWithResponseCounts.count
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return questionsWithResponseCounts.allKeys[section] as String
    }
    
}
