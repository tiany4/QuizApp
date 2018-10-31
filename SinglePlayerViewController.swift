import UIKit
import CoreMotion

class SinglePlayerViewController: UIViewController {
    /*******************************************************************************************************
     *
     * Button Declared
     *
     *******************************************************************************************************/
    @IBOutlet weak var answerButton1: UIButton!
    @IBOutlet weak var answerButton2: UIButton!
    @IBOutlet weak var answerButton3: UIButton!
    @IBOutlet weak var answerButton4: UIButton!
    /*******************************************************************************************************
     *
     * Label Declared
     *
     *******************************************************************************************************/
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var questionSentenceLabel: UILabel!
    @IBOutlet weak var trueAnswerLabel: UILabel!
    
    var gameType = ""
    var questionList = [Quiz]()
    var timer : Timer?
    var answerTimer: Timer?
    var motionTimer: Timer?
    var countDownTime = 20
    var currentQuestionNumber = 0
    var currentQuestion : Quiz!
    var currentQuizNumber = 1
    var chosenAnswer = ""
    var score = 0
    var motionStuff = myCoreMotion()
    var submitted = false
    /*******************************************************************************************************
     *
     * View Functions
     *
     *******************************************************************************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        getQuestions()
        let bg = UIImageView(frame: UIScreen.main.bounds)
        bg.image = UIImage(named:"bg")
        bg.contentMode = UIViewContentMode.scaleAspectFill
        bg.alpha = 0.5
        self.view.insertSubview(bg, at: 0)
        // custom back button
        self.navigationItem.hidesBackButton = true
        let customBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SinglePlayerViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = customBackButton
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    /*******************************************************************************************************
     *
     * Grabs data, read and display questions
     *
     *******************************************************************************************************/
    func getQuestions() {
        let address = "https://www.people.vcu.edu/~ebulut/jsonFiles/quiz\(currentQuizNumber).json"
        let url = URL(string: address)
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url!, completionHandler: { (data, response, error) in
            if let result = data {
                do {
                    let object = try JSONSerialization.jsonObject(with: result, options: .allowFragments)
                    if let questions = object as? [String:Any] {
                        self.readQuestions(questionData: questions)
                    }
                }
                catch {
                    self.currentQuizNumber = 1
                    self.getQuestions()
                }
            }
        })
        dataTask.resume()
    }
    func readQuestions(questionData: [String:Any]) {
        self.navigationItem.title = questionData["topic"] as? String
        let questions = questionData["questions"] as! [NSDictionary]
        for question in questions {
            let number = question["number"] as! Int
            let questionSentence = question["questionSentence"] as! String
            let options = question["options"] as! NSDictionary
            let correctOption = question["correctOption"] as! String
            let temp = Quiz(number: number,
                            sentence: questionSentence,
                            correctOption: correctOption,
                            options: options)
            questionList.append(temp)
        }
        gameStart()
    }
    func showQuestion() {
        currentQuestion = questionList[currentQuestionNumber]
        questionSentenceLabel.text = currentQuestion.sentence
        answerButton1.setTitle("A) \(currentQuestion.options["A"]!)", for: .normal)
        answerButton2.setTitle("B) \(currentQuestion.options["B"]!)", for: .normal)
        answerButton3.setTitle("C) \(currentQuestion.options["C"]!)", for: .normal)
        answerButton4.setTitle("D) \(currentQuestion.options["D"]!)", for: .normal)
        currentQuestionNumber += 1
    }
    /*******************************************************************************************************
     *
     * Game Start and ends
     *
     *******************************************************************************************************/
    func gameStart() {
        DispatchQueue.main.async {
            // Must be used from main thread only
            self.showQuestion()
            self.timerLabel.text = "Remaining time: " + String(self.countDownTime)
            self.startTimer()
        }
    }
    func endGame() {
        questionList.removeAll()
        timer?.invalidate()
        answerTimer?.invalidate()
        motionTimer?.invalidate()
        countDownTime = 20
        currentQuestionNumber = 0
        motionStuff.stopMotionUpdate()
        
        let alert = UIAlertController(title: "Game over!", message: "Your score: \(score)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Home", style: .cancel, handler: { action in
            self.navigationController?.popToRootViewController(animated: false)
        }))
        alert.addAction(UIAlertAction(title: "Next Game", style: .default, handler: { action in
            self.currentQuizNumber += 1
            self.score = 0
            self.trueAnswerLabel.text = ""
            self.motionStuff = myCoreMotion()
            self.getQuestions()
            self.answerButton1.isSelected = false
            self.answerButton2.isSelected = false
            self.answerButton3.isSelected = false
            self.answerButton4.isSelected = false
            self.answerButton1.isUserInteractionEnabled = true
            self.answerButton2.isUserInteractionEnabled = true
            self.answerButton3.isUserInteractionEnabled = true
            self.answerButton4.isUserInteractionEnabled = true
        }))
        self.present(alert, animated: true)
    }
    /*******************************************************************************************************
     *
     * Button functions
     *
     *******************************************************************************************************/
    @IBAction func selectA(_ sender: Any) {
        if (chosenAnswer == "A") {
            endCurrentQuestion()
            return
        }
        chosenAnswer = "A"
        answerButton1.isSelected = true
        answerButton2.isSelected = false
        answerButton3.isSelected = false
        answerButton4.isSelected = false
    }
    @IBAction func selectB(_ sender: Any) {
        if (chosenAnswer == "B") {
            endCurrentQuestion()
            return
        }
        chosenAnswer = "B"
        answerButton1.isSelected = false
        answerButton2.isSelected = true
        answerButton3.isSelected = false
        answerButton4.isSelected = false
    }
    @IBAction func selectC(_ sender: Any) {
        if (chosenAnswer == "C") {
            endCurrentQuestion()
            return
        }
        chosenAnswer = "C"
        answerButton1.isSelected = false
        answerButton2.isSelected = false
        answerButton3.isSelected = true
        answerButton4.isSelected = false
    }
    @IBAction func selectD(_ sender: Any) {
        if (chosenAnswer == "D") {
            endCurrentQuestion()
            return
        }
        chosenAnswer = "D"
        answerButton1.isSelected = false
        answerButton2.isSelected = false
        answerButton3.isSelected = false
        answerButton4.isSelected = true
    }
    /*******************************************************************************************************
     *
     * Timer
     *
     *******************************************************************************************************/
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updatePerSecond), userInfo: nil, repeats: true)
        motionTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateMotion), userInfo: nil, repeats: true)
    }
    @objc
    func updatePerSecond() {
        // update countdown timer
        countDownTime -= 1
        timerLabel.text = "Remaining time: " + String(countDownTime)
        if countDownTime == 0 {
            endCurrentQuestion()
        }
    }
    /*******************************************************************************************************
     *
     * Motion
     *
     *******************************************************************************************************/
    @objc
    func updateMotion() {
        motionSelectAnswer(direction: motionStuff.updateDeviceMotion())
    }
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        motionStuff.blockMotion = true
        print("Shaking")
    }
    
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (!submitted) {
            pickRandomAnswer()
            print("Selected random answer")
        }
        motionStuff.motionBlockTimer()
    }
    
    func motionSelectAnswer(direction: String) {
        switch direction {
        case "D":
            if (chosenAnswer == "B") {
                selectA(self)
            } else
                if (chosenAnswer == "D") {
                    selectC(self)
            }
        case "U":
            if (chosenAnswer == "A") {
                selectB(self)
            } else
                if (chosenAnswer == "C") {
                    selectD(self)
            }
        case "L":
            if (chosenAnswer == "C") {
                selectA(self)
            } else
                if (chosenAnswer == "D") {
                    selectB(self)
            }
        case "R":
            if (chosenAnswer == "A") {
                selectC(self)
            } else
                if (chosenAnswer == "B") {
                    selectD(self)
            }
        case "S":
            if (chosenAnswer != "") {
                endCurrentQuestion()
            }
        default:
            // nothing happens
            return
        }
    }
    
    // Ugliest code I've ever written
    func pickRandomAnswer() {
        if (chosenAnswer == "A") {
            switch arc4random_uniform(3) {
            case 0:
                selectB(self)
            case 1:
                selectC(self)
            case 2:
                selectD(self)
            default:
                print("nonono")
            }
        } else
            if (chosenAnswer == "B") {
                switch arc4random_uniform(3) {
                case 0:
                    selectA(self)
                case 1:
                    selectC(self)
                case 2:
                    selectD(self)
                default:
                    print("nonono")
                }
            } else
                if (chosenAnswer == "C") {
                    switch arc4random_uniform(3) {
                    case 0:
                        selectA(self)
                    case 1:
                        selectB(self)
                    case 2:
                        selectD(self)
                    default:
                        print("nonono")
                    }
                } else
                    if (chosenAnswer == "D") {
                        switch arc4random_uniform(3) {
                        case 0:
                            selectA(self)
                        case 1:
                            selectB(self)
                        case 2:
                            selectC(self)
                        default:
                            print("nonono")
                        }
                    } else {
                        switch arc4random_uniform(4) {
                        case 0:
                            selectA(self)
                        case 1:
                            selectB(self)
                        case 2:
                            selectC(self)
                        case 3:
                            selectD(self)
                        default:
                            print("nonono")
                        }
        }
    }
    /*******************************************************************************************************
     *
     * Question Ends and quiz
     *
     *******************************************************************************************************/
    func endCurrentQuestion() {
        if (chosenAnswer == currentQuestion.correctOption) {
            score += 1
        }
        submitted = true
        timer?.invalidate()
        motionTimer?.invalidate()
        answerButton1.isUserInteractionEnabled = false
        answerButton2.isUserInteractionEnabled = false
        answerButton3.isUserInteractionEnabled = false
        answerButton4.isUserInteractionEnabled = false
        trueAnswerLabel.text = "Correct Answer: \(currentQuestion.correctOption)"
        answerTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(nextQuestion), userInfo: nil, repeats: false)
    }
    @objc
    func nextQuestion() {
        if currentQuestionNumber == questionList.count {
            endGame()
            return
        }
        chosenAnswer = ""
        answerButton1.isSelected = false
        answerButton2.isSelected = false
        answerButton3.isSelected = false
        answerButton4.isSelected = false
        answerButton1.isUserInteractionEnabled = true
        answerButton2.isUserInteractionEnabled = true
        answerButton3.isUserInteractionEnabled = true
        answerButton4.isUserInteractionEnabled = true
        submitted = false
        countDownTime = 20
        trueAnswerLabel.text = ""
        showQuestion()
        startTimer()
    }
    /*******************************************************************************************************
     *
     * Back button
     *
     *******************************************************************************************************/
    @objc func back(sender: UIBarButtonItem) {
        questionList.removeAll()
        timer?.invalidate()
        answerTimer?.invalidate()
        motionTimer?.invalidate()
        countDownTime = 20
        currentQuestionNumber = 0
        motionStuff.stopMotionUpdate()
        self.navigationController?.popToRootViewController(animated: false)
    }
}
