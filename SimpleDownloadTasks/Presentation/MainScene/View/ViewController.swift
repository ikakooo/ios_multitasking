//
//  ViewController.swift
//  SimpleDownloadTasks
//
//  Created by user200328 on 6/23/21.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - Variables
    var downloadTasks = [DownloadTask]() {
        didSet {
            downloadsTableView.reloadData()
        }
    }
    var completedTasks = [DownloadTask]() {
        didSet {
            completedTableView.reloadData()
        }
    }
    
    var option: SimulationOption!
    
    // MARK: - IBOutlets
    @IBOutlet weak var downloadsTableView: UITableView!
    @IBOutlet weak var completedTableView: UITableView!
    
    @IBOutlet weak var allTasksCount: UILabel!
    @IBOutlet weak var allTasksCountSlider: UISlider!
    @IBOutlet weak var isRandomized: UISwitch!
    @IBOutlet weak var paralellTasks: UILabel!
    @IBOutlet weak var ParalellTasksSlider: UISlider!
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadsTableView.dataSource = self
        completedTableView.dataSource = self
        downloadsTableView.register(UINib(nibName: "ProgressCell", bundle: nil), forCellReuseIdentifier: "ProgressCell")
        completedTableView.register(UINib(nibName: "ProgressCell", bundle: nil), forCellReuseIdentifier: "ProgressCell")
        option = SimulationOption(jobCount: 1, maxAsyncTasks: 2, isRandomizedTime: true)
    }
    @IBAction func onAllTasksCountSlider(_ sender: UISlider) {
        option.jobCount = Int(sender.value)
        allTasksCount.text = "\(option.jobCount) Tasks"
    }
    @IBAction func swtchIsRandomised(_ sender: UISwitch) {
        option.isRandomizedTime = sender.isOn
    }
    @IBAction func onParalellTasksSlider(_ sender: UISlider) {
        option.maxAsyncTasks = Int(sender.value)
        paralellTasks.text = "\(option.maxAsyncTasks) Max Parallel Running Tasks"
    }
    
    
    
    // MARK: - Task Starter
    @IBAction func startTasks(_ sender: UIButton) {
        sender.isEnabled = false
        allTasksCountSlider.isEnabled = false
        isRandomized.isEnabled = false
        ParalellTasksSlider.isEnabled = false
        downloadTasks = []
        completedTasks = []
        
    // მოახდინეთ DispatchQueue, DispatchGroup და DispatchSemaphore-ის ინიციალიზაცია
        let semaphore = DispatchSemaphore(value: option.maxAsyncTasks)
        let dispatchGroup = DispatchGroup()
        let imageFetcherQueue = DispatchQueue(label: "image.fetcher.queue", attributes: .concurrent)
        
    // შეავსეთ  მასივ(ებ)ი ტასკების სტატუსების მიხედვით
        
        
        DownloadTask(identifier: "1"){ [weak self]downloadTask in
            self?.downloadTasks.append(downloadTask)
        }.startTask(queue: imageFetcherQueue, group: dispatchGroup, semaphore: semaphore)
        
        downloadTasks = (1...option.jobCount).map({ (i) -> DownloadTask in
                    let identifier = "\(i)"
                    return DownloadTask(identifier: identifier, stateUpdateHandler: { (task) in
                        DispatchQueue.main.async { [weak self] in
                            
                            guard let index = self?.downloadTasks.indexOfTaskWith(identifier: identifier) else {
                                return
                            }
                            
                            switch task.state {
                            case .completed:
                                self?.downloadTasks.remove(at: index)
                                self?.completedTasks.insert(task, at: 0)
                                
                            case .pending, .inProgess:
                                guard let cell = self?.downloadsTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ProgressCell else {
                                    return
                                }
                                cell.configure(with: task)
                                self?.downloadsTableView.beginUpdates()
                                self?.downloadsTableView.endUpdates()
                            }
                        }
                    })
                })
       
        
    // დაიწყეთ ჩამოტვირთვა ტასკების
        downloadTasks.forEach {
                   $0.startTask(queue: imageFetcherQueue, group: dispatchGroup, semaphore: semaphore)
               }
    // აქ აჩვენეთ ალერტი, რომ ყველა ტასკი დასრულებულია
        dispatchGroup.notify(queue: .main) { [weak self] in
            sender.isEnabled = true
            self?.allTasksCountSlider.isEnabled = true
            self?.isRandomized.isEnabled = true
            self?.ParalellTasksSlider.isEnabled = true
            self?.presentAlertWith(title: "The End", message: "all downloads complated")
        }
    }
    
    private func presentAlertWith(title: String , message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true)
    }
    
}

// MARK: - UITableView Data Source
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == downloadsTableView {
            return downloadTasks.count
        }
        return completedTasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProgressCell", for: indexPath) as! ProgressCell
        
        //print(indexPath.row)
       // cell.delegate = self
       // cell.configure(with: postsList[indexPath.row])
        
        if tableView == downloadsTableView {
            cell.configure(with: downloadTasks[indexPath.row])
        }else {
            cell.configure(with: completedTasks[indexPath.row])
        }
        
        
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView === downloadsTableView {
            return "Download Queue (\(downloadTasks.count))"
        } else if tableView === completedTableView {
            return "Completed (\(completedTasks.count))"
        } else {
            return nil
        }
    }

}
// იმპლემენტაცია ამ დელეგატის
