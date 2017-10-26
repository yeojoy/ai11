//
//  MainViewController.swift
//  ai11
//
//  Created by Yeojong Kim on 2017. 10. 26..
//  Copyright © 2017년 Yeojong Kim. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let sampleData = SampleData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Android onCreate과 비슷함. 처음 실행할 때 1번 실행
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView(frame: .zero)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Android onResume과 비슷함.
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Android onPause와 비슷함.
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sampleData.samples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainFeatureCell", for: indexPath) as! MainFeatureCell
        let sample = self.sampleData.samples[indexPath.row]
        cell.titleLabel.text = sample.title
        cell.descriptionLabel.text = sample.description
        cell.fetaureImageCell.image = UIImage(named: sample.image)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 돌아왔을 때 선택됐던 하이라이트를 제거할 때 사용
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sample = self.sampleData.samples[indexPath.row]
        print("\(sample.title) -> 이거가 선택 됨")
        
        switch indexPath.row {
        case 0:
            self.performSegue(withIdentifier: "photoObjectDetection", sender: nil)
            break
        case 1:
            self.performSegue(withIdentifier: "realtimeDetection", sender: nil)
            break
        case 2:
            self.performSegue(withIdentifier: "facialAnalysis", sender: nil)
            break
        default:
            return
        }
    }
}
