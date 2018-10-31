import UIKit
import MultipeerConnectivity



class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    var isConnected = false
    var run = true
    /*******************************************************************************************************
     *
     * Button Declared
     *
     *******************************************************************************************************/
    @IBOutlet weak var singleButton: UIButton!
    @IBOutlet weak var multiButton: UIButton!
    @IBOutlet weak var pureisudeishion: UIButton!
    /*******************************************************************************************************
     *
     * REQUIRED Multipeer Connectivity Variables
     *
     *******************************************************************************************************/
    var peerID:MCPeerID!
    var mcSession:MCSession!
    var mcAdvAss:MCAdvertiserAssistant!
    /*******************************************************************************************************
     *
     * View Functons
     *
     *******************************************************************************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        let bg = UIImageView(frame: UIScreen.main.bounds)
        bg.image = UIImage(named:"bg")
        bg.contentMode = UIViewContentMode.scaleAspectFill
        bg.alpha = 0.5
        self.view.insertSubview(bg, at: 0)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Connect", style: .plain, target: self, action: #selector(connect))
    }
    override func viewDidAppear(_ animated: Bool){
        if run {
            setupConnectivity() //refer to Sub Functions
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    /*******************************************************************************************************
     *
     * Buttons Function
     *
     *******************************************************************************************************/
    @IBAction func clickSingle(_ sender: Any) {
        singleButton.isSelected = true
        multiButton.isSelected = false
    }
    @IBAction func clickMulti(_ sender: Any) {
        singleButton.isSelected = false
        multiButton.isSelected = true
    }
    @IBAction func gameStart(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        /*-----------------------------------------------------------------------------------------------------
         - Single
         ------------------------------------------------------------------------------------------------------*/
        if singleButton.isSelected {
            if (isConnected) {
                let alert = UIAlertController(title: "Connected", message: "You will be disconnected from the session if you start a single player game.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                    return
                }))
                alert.addAction(UIAlertAction(title: "Start", style: .default, handler: { action in
                    self.disconnectself() //refer to Sub Functions
                    let nextViewController = storyBoard.instantiateViewController(withIdentifier: "QuizSingle") as! SinglePlayerViewController
                    nextViewController.gameType = "single"
                    self.navigationController?.pushViewController(nextViewController, animated: true)
                }))
                self.present(alert, animated: true)
            } else {
                self.disconnectself() //refer to Sub Functions
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "QuizSingle") as! SinglePlayerViewController
                nextViewController.gameType = "single"
                self.navigationController?.pushViewController(nextViewController, animated: true)
            }
        }
            /*-----------------------------------------------------------------------------------------------------
             - MultiPlayer
             ------------------------------------------------------------------------------------------------------*/
        else if multiButton.isSelected{
            self.multiError() //refer to Sub Functions
            self.sendMessage(msg:"multiStart") //refer to Sub Functions
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "QuizMulti") as! MultiPlayerViewController
            nextViewController.gameType = "multi"
            nextViewController.peerID = self.peerID
            nextViewController.mcSession = self.mcSession
            self.disconnectself() //refer to Sub Functions
            navigationController?.pushViewController(nextViewController, animated: true)
        }
    }
    /*******************************************************************************************************
     *
     * Right Nav Bar connect button function
     *
     *******************************************************************************************************/
    @objc
    func connect()  {
        let actionSheet = UIAlertController(title: "New Multiplayer Game", message: "Do you want to Host or Join a session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Host Session", style: .default, handler: { (action:UIAlertAction) in
            
            self.mcAdvAss = MCAdvertiserAssistant(serviceType: "ba-td", discoveryInfo: nil, session: self.mcSession)
            self.mcAdvAss.start()
            self.changeRightNavBT(title: "Hosting", enabled: false) //refer to Sub Functions
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Join Session", style: .default, handler: { (action:UIAlertAction) in
            let mcBrowser = MCBrowserViewController(serviceType: "ba-td", session: self.mcSession)
            mcBrowser.delegate = self
            self.present(mcBrowser, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    /*******************************************************************************************************
     *
     * Sub Functions
     *
     *******************************************************************************************************/
    func setupConnectivity(){
        disconnectSession()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID)
        mcSession.delegate = self
    }
    func disconnectSession (){
        self.mcAdvAss?.stop()
        self.mcSession?.disconnect()
    }
    func disconnectself (){
        self.run = true
        self.isConnected = false
        self.changeRightNavBT(title: "Connect", enabled: true)
    }
    func multiError (){
        if (mcSession.connectedPeers.count < 1 || mcSession.connectedPeers.count > 3) {
            let alert = UIAlertController(title: "Error", message: "Must have 2-4 players.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
    }
    func sendMessage (msg: String){
        let msg = msg
        let dataToSend =  NSKeyedArchiver.archivedData(withRootObject: msg)
        do{
            try mcSession.send(dataToSend, toPeers: mcSession.connectedPeers, with: .unreliable)
        }
        catch {
            //print("Error in sending data \(err)")
        }
    }
    func changeRightNavBT (title: String, enabled: Bool){
        self.navigationItem.rightBarButtonItem?.title = title
        
        //Currently have to restart app to be able to click the button if we want to change between host/join
        //self.navigationItem.rightBarButtonItem?.isEnabled = enabled
    }
    /*******************************************************************************************************
     *
     * All Session Required Function
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
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("inside didReceiveData")
        
        // this needs to be run on the main thread
        DispatchQueue.main.async(execute: {
            
            if let receivedString = NSKeyedUnarchiver.unarchiveObject(with: data) as? String{
                if (receivedString == "multiStart") {
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                    let nextViewController = storyBoard.instantiateViewController(withIdentifier: "QuizMulti") as! MultiPlayerViewController
                    nextViewController.gameType = "multi"
                    nextViewController.peerID = self.peerID
                    nextViewController.mcSession = self.mcSession
                    self.changeRightNavBT(title: "Connect", enabled: true) //refer to Sub Functions
                    self.navigationController?.pushViewController(nextViewController, animated: true)
                }
            }
        })
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    /*******************************************************************************************************
     *
     * Browser Back and Done Function
     *
     *******************************************************************************************************/
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
        run = false
        isConnected = true
        self.changeRightNavBT(title: "Connected", enabled: false)
    }
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
        run = false
    }
    
    
    
}

