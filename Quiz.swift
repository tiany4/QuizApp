import Foundation

class Quiz {
    
    var number: Int
    var sentence: String
    var correctOption: String
    var options: NSDictionary
    
    init(number: Int, sentence: String, correctOption: String, options: NSDictionary) {
        self.number = number
        self.sentence = sentence
        self.correctOption = correctOption
        self.options = options
    }
    
}
