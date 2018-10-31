import UIKit
import MultipeerConnectivity
import CoreMotion

class MultiPlayerViewController: UIViewController, MCSessionDelegate {
    
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
    @IBOutlet weak var p1answerLabel: UILabel!
    @IBOutlet weak var p2answerLabel: UILabel!
    @IBOutlet weak var p3answerLabel: UILabel!
    @IBOutlet weak var p4answerLabel: UILabel!
    @IBOutlet weak var questionSentenceLabel: UILabel!
    @IBOutlet weak var trueAnswerLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    /*******************************************************************************************************
     *
     * Multipeer Connectivity
     *
     *******************************************************************************************************/
    var peerID:MCPeerID!
    var mcSession:MCSession!
    
    var answerLabelList = [UILabel]()
    var answerCount = 0
    var peerScore = [String]()
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
    var alert : UIAlertController?
    var submitted = false
    /*******************************************************************************************************
     *
     * View
     *
     *******************************************************************************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mcSession.delegate = self
        
        getQuestions()
        
        p1answerLabel.text = ""
        p2answerLabel.text = ""
        p3answerLabel.text = ""
        p4answerLabel.text = ""
        
        answerLabelList.append(p2answerLabel)
        answerLabelList.append(p3answerLabel)
        answerLabelList.append(p4answerLabel)
        
        for _ in 0...mcSession.connectedPeers.count - 1 {
            peerScore.append("")
        }
        
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
     * Grabbing Data Function, Reading and displaying
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
     * Button Function
     *
     *******************************************************************************************************/
    @IBAction func selectA(_ sender: Any) {
        if (chosenAnswer == "A") {
            self.chooseAnswer()
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
            self.chooseAnswer()
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
            self.chooseAnswer()
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
            self.chooseAnswer()
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
     * Start and End Game
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
        self.stopBGProcesses() // refer to sub function
        var title = ""
        switch checkWin() {
        case true:
            title = "You won!"
        case false:
            title = "You lost!"
        }
        // Multiplayer end game score message
        var msg = "Your score: \(score)"
        for i in 0...mcSession.connectedPeers.count - 1{
            msg += "\nPlayer \(i+2): \(peerScore[i])"
        }
        self.alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        self.alert?.addAction(UIAlertAction(title: "Home", style: .cancel, handler: { action in
            self.mcSession.disconnect()
            self.navigationController?.popToRootViewController(animated: false)
        }))
        self.alert?.addAction(UIAlertAction(title: "Next Game", style: .default, handler: { action in
            self.sendMsg(msg:"nextgame") //refer to sub Functions
            self.nextQuiz()
        }))
        self.present(self.alert!, animated: true)
    }
    func checkWin() -> Bool{
        var scoreToInts = [Int]()
        for i in 0...peerScore.count - 1 {
            scoreToInts.append(Int(peerScore[i])!)
        }
        if (scoreToInts.max()! <= score) {
            return true
        } else {
            return false
        }
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
    func updateMotion() {
        motionSelectAnswer(direction: motionStuff.updateDeviceMotion())
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
     * Left Nav Bar Back Function
     *
     *******************************************************************************************************/
    @objc
    func back(sender: UIBarButtonItem) {
        self.alert = UIAlertController(title: "Quit the game?", message: "", preferredStyle: .alert)
        self.alert?.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.alert?.addAction(UIAlertAction(title: "Sure", style: .default, handler: { action in
            self.mcSession.disconnect()
            self.stopBGProcesses() //refer to sub functions
            self.navigationController?.popToRootViewController(animated: false)
        }))
        self.present(alert!, animated: true)
    }
    /*******************************************************************************************************
     *
     * Question and Quiz
     *
     *******************************************************************************************************/
    func endCurrentQuestion() {
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
        countDownTime = 20
        resetUI()
        enableAnswer()
        showQuestion()
        startTimer()
    }
    func nextQuiz() {
        currentQuizNumber += 1
        score = 0
        resetUI()
        enableAnswer()
        getQuestions()
        self.alert?.dismiss(animated: true, completion: nil)
    }
    /*******************************************************************************************************
     *
     * Motion
     *
     *******************************************************************************************************/
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
     * Send Data
     *
     *******************************************************************************************************/
    func sendMsg (msg : String){
        let msg = msg
        let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: msg)
        do {
            try mcSession.send(dataToSend, toPeers: mcSession.connectedPeers, with: .unreliable)
        } catch {
            print("error")
        }
    }
    /*******************************************************************************************************
     *
     * Sub Functions
     *
     *******************************************************************************************************/
    func chooseAnswer(){
        answerCount += 1
        if (chosenAnswer == currentQuestion.correctOption) {
            score += 1
        }
        p1answerLabel.text = "I have chosen \(chosenAnswer)"
        sendMsg(msg: "\(chosenAnswer) \(score)")
        if self.answerCount == self.mcSession.connectedPeers.count + 1 {
            self.endCurrentQuestion()
        }
        answerButton1.isUserInteractionEnabled = false
        answerButton2.isUserInteractionEnabled = false
        answerButton3.isUserInteractionEnabled = false
        answerButton4.isUserInteractionEnabled = false
    }
    func enableAnswer() {
        answerButton1.isSelected = false
        answerButton2.isSelected = false
        answerButton3.isSelected = false
        answerButton4.isSelected = false
        answerButton1.isUserInteractionEnabled = true
        answerButton2.isUserInteractionEnabled = true
        answerButton3.isUserInteractionEnabled = true
        answerButton4.isUserInteractionEnabled = true
    }
    func stopBGProcesses(){
        self.questionList.removeAll()
        self.timer?.invalidate()
        self.answerTimer?.invalidate()
        self.motionTimer?.invalidate()
        self.countDownTime = 20
        self.currentQuestionNumber = 0
    }
    func resetUI(){
        p1answerLabel.text = ""
        p2answerLabel.text = ""
        p3answerLabel.text = ""
        p4answerLabel.text = ""
        trueAnswerLabel.text = ""
        chosenAnswer = ""
        answerCount = 0
    }
    /*******************************************************************************************************
     *
     * Session
     *
     *******************************************************************************************************/
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    /*******************************************************************************************************
     *
     * RECEIVES DATA
     *
     *******************************************************************************************************/
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // this needs to be run on the main thread
        DispatchQueue.main.async(execute: {
            if let receivedString = NSKeyedUnarchiver.unarchiveObject(with: data) as? String{
                if (receivedString == "nextgame") {
                    self.nextQuiz()
                    return
                }else {
                    var myData = receivedString.split(separator: " ")
                    self.answerLabelList[self.mcSession.connectedPeers.index(of: peerID)!].text = "Player: \(peerID.displayName) chose \(myData[0])"
                    self.peerScore[self.mcSession.connectedPeers.index(of: peerID)!] = "\(myData[1])"
                    self.answerCount += 1
                }
            }
            if self.answerCount == self.mcSession.connectedPeers.count + 1 {
                self.endCurrentQuestion()
            }
        })
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}
