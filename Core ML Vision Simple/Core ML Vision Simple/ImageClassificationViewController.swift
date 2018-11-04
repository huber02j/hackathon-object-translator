/**
 * Copyright IBM Corporation 2017, 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit
import CoreML
import Vision
import ImageIO
import UIKit
import AVFoundation

//import Restkit
//import LanguageTranslatorV3





//import TextToSpeechV1


class ImageClassificationViewController: UIViewController {
    // MARK: - IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var classificationLabel: UILabel!
    
    // MARK: - Image Classification
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Initialize Vision Core ML model from base Watson Visual Recognition model

            //  Uncomment this line to use the tools model.
            let model = try VNCoreMLModel(for: watson_tools().model)
            

            //  Uncomment this line to use the plants model.
            // let model = try VNCoreMLModel(for: watson_plants().model)

            // Create visual recognition request using Core ML model

            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            }
            
            request.imageCropAndScaleOption = .scaleFit
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func updateClassifications(for image: UIImage) {
        classificationLabel.text = "Classifying..."
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                
                let sema = DispatchSemaphore(value: 0)
                try handler.perform([self.classificationRequest])
                _ = sema.wait(timeout: .distantFuture)
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    /// Updates the UI with the results of the classification.
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.classificationLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
            
            if classifications.isEmpty {
                self.classificationLabel.text = "Nothing recognized."
            } else {
                // Display top classification ranked by confidence in the UI.
                // server endpoint
                
                let myGroup = DispatchGroup()
                
                myGroup.enter()
                //// Do your task
                

                    
                // LANGAUGE TRANSLATE API REQUEST
                var v = ""
                let login = "test"
                let passwor = "12345"
                
                let url = URL(string: "https://gateway.watsonplatform.net/language-translator/api/v3/translate?version=2018-05-01")
                var request = URLRequest(url: url!)
                
                let config = URLSessionConfiguration.default
                let userPasswordString = "\(login):\(passwor)"
                let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
                let base64EncodedCredential = "YXBpa2V5OkZuLVNsRjdsT1JxdlN5SHBUelNrV0c0bEF6Z3Vrdzg2UFlaMmpXUHVsSldq"
                let authString = "Basic \(base64EncodedCredential)"
                config.httpAdditionalHeaders = ["Content-Type":"application/json"]
                config.httpAdditionalHeaders = ["Authorization" : authString]
                
                // API PARAMETERS
                let json: [String: Any] = ["model_id": "en-es",
                                           "text": ["\(classifications[0].identifier)"]]
                
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                let username = "apikey"
                let password = "Fn-SlF7lORqvSyHpTzSkWG4lAzgukw86PYZ2jWPulJWj"
                let loginString = String(format: "%@:%@", username, password)
                let loginData = loginString.data(using: .utf8)!
                let base64LoginString = loginData.base64EncodedString()
                
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
                request.httpBody = jsonData
                request.httpMethod = "POST"
                let session = URLSession(configuration: config)
                print(request)
                let task = session.dataTask(with: request as URLRequest) { data, response, error in
                    guard let data = data, error == nil else {
                        print(error?.localizedDescription ?? "No data")
                        return
                    }
                    let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                    if let responseJSON = responseJSON as? [String: Any] {
                        //print(responseJSON["translations"][0])
                        var ty = type(of: responseJSON)
                        if var t = responseJSON["translations"] as? [[String:String]] {

                            v = t[0]["translation"]!
                            print(v)
                         self.classificationLabel.text = classifications[0].identifier + " --> " + v

                            myGroup.leave() //// When your task completes
                        }
                        
                        //print(t)
                    }
                    else {
                        print("HAHHAH\nAHHAH\nAHAHHA")
                    }

                }


                task.resume()
                
                

                myGroup.wait()

                print("HIIIII")
                myGroup.notify(queue: .main) {
                    print(v)
                    self.classificationLabel.text = classifications[0].identifier + " --> " + v
                }

            }
        }
    }
    
    // MARK: - Photo Actions
    
    @IBAction func takePicture() {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    
}

extension ImageClassificationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Handling Image Picker Selection
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        
        // We always expect `imagePickerController(:didFinishPickingMediaWithInfo:)` to supply the original image.
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.image = image
        
        
        
        //let apiKey = "iSo1iNVoM4AFyaHPKAkcnSkllyL_6DF1exrGdx2l1tNY"
        //let version = "2018-11-03" // use today's date for the most recent version
        //let visualRecognition = VisualRecognition(version: version, apiKey: apiKey)
        
        //let url = "https://gateway.watsonplatform.net/visual-recognition/api"
        //let failure = { (error: Error) in print(error) }
        //visualRecognition.classify(image: url, failure: failure) { classifiedImages in
        //classifiedImagesprint(classified)
        //}
        
        updateClassifications(for: image)
    }
}

