import Foundation
import UIKit

class GameoverViewController: ViewController {
    
    var myScore = 0
    var p2Score = ""
    var p3Score = ""
    var p4Score = ""
    
    var gameType = ""

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var p2Label: UILabel!
    @IBOutlet weak var p3Label: UILabel!
    @IBOutlet weak var p4Label: UILabel!
    @IBOutlet weak var goHomeButton: UIButton!
    @IBOutlet weak var restartButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Game Over!"
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        scoreLabel.text = "Your score: \(myScore)"
        
        if gameType == "multi"{
        var myData = p2Score.split(separator: " ")
        p2Label.text = "\(myData[0]) score: \(myData[1])"
            if p3Score != "" {
        myData = p3Score.split(separator: " ")
        p3Label.text = "\(myData[0]) score: \(myData[1])"
            }else{
                p3Label.text = ""
            }
            if p4Score != "" {
        myData = p4Score.split(separator: " ")
        p4Label.text = "\(myData[0]) score: \(myData[1])"
            }else{
                p4Label.text = ""
            }
        }else{
            p2Label.text = ""
            p3Label.text = ""
            p4Label.text = ""
        }
    }
    
    @IBAction func goHome(_ sender: Any) {
        navigationController?.popToRootViewController(animated: false)
    }
    
    @IBAction func nextGame(_ sender: Any) {
        switch gameType {
        case "multi":
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "QuizMulti") as! MultiPlayerViewController
            nextViewController.currentQuizNumber += 1
            
            self.navigationController?.pushViewController(nextViewController, animated: true)
        case "single":
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "QuizSingle") as! SinglePlayerViewController
            nextViewController.currentQuizNumber += 1
            
            self.navigationController?.pushViewController(nextViewController, animated: true)
        default:
            return
        }
    }
    
}
