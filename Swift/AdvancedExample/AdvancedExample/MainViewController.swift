import GoogleInteractiveMediaAds
import UIKit

class MainViewController: UIViewController {

  // Handle to TableView.
  @IBOutlet var tableView: UITableView!

  // Input field for language pop-up.
  @IBOutlet weak var languageInput: UITextField?

  // Storage point for videos.
  var videos: NSArray!
  var adsLoader: IMAAdsLoader?
  var language = "en"

  // Set up the app.
  override func viewDidLoad() {
    super.viewDidLoad()
    initVideos()
    setUpAdsLoader()

    // For PiP.
    do {
      try AVAudioSession.sharedInstance().setActive(true)
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
    } catch {
      NSLog("Error setting background playback - PiP will not work.")
    }
  }

  // Populate the video array.
  func initVideos() {
    let dfpThumbnail = UIImage(named: "dfp.png")
    let androidThumbnail = UIImage(named: "android.png")
    let bunnyThumbnail = UIImage(named: "bunny.png")
    let bipThumbnail = UIImage(named: "bip.png")

    videos = [
      Video(
        title: "Pre-roll",
        thumbnail: dfpThumbnail,
        video: kDFPContentPath,
        tag: kPrerollTag),
      Video(
        title: "Skippable Pre-roll",
        thumbnail: androidThumbnail,
        video: kAndroidContentPath,
        tag: kSkippableTag),
      Video(
        title: "Post-roll",
        thumbnail: bunnyThumbnail,
        video: kBigBuckBunnyContentPath,
        tag: kPostrollTag),
      Video(
        title: "AdRules",
        thumbnail: bipThumbnail,
        video: kBipBopContentPath,
        tag: kAdRulesTag),
      Video(
        title: "AdRules Pods",
        thumbnail: dfpThumbnail,
        video: kDFPContentPath,
        tag: kAdRulesPodsTag),
      Video(
        title: "VMAP Pods",
        thumbnail: androidThumbnail,
        video: kAndroidContentPath,
        tag: kVMAPPodsTag),
      Video(
        title: "Wrapper",
        thumbnail: bunnyThumbnail,
        video: kBigBuckBunnyContentPath,
        tag: kWrapperTag),
      Video(
        title: "AdSense",
        thumbnail: bipThumbnail,
        video: kBipBopContentPath,
        tag: kAdSenseTag),
      Video(
        title: "Custom",
        thumbnail: androidThumbnail,
        video: kAndroidContentPath,
        tag: "custom"),
    ]
  }

  // Initialize AdsLoader.
  func setUpAdsLoader() {
    if adsLoader != nil {
      adsLoader = nil
    }
    let settings = IMASettings()
    settings.language = language
    settings.enableBackgroundPlayback = true
    adsLoader = IMAAdsLoader(settings: settings)
  }

  // Show the language pop-up.
  @IBAction func onLanguageClicked() {
    let alertMessage =
      "NOTE: This will only change the ad UI language. The language elsewhere"
      + " in the app will remain in English. Language must be formatted as a canonicalized IETF"
      + " BCP 47 language identifier such as would be returned by [NSLocale preferredLanguages],"
      + " for example, \"en\", \"es\", etc."

    let languagePrompt = UIAlertController(
      title: "Language",
      message: alertMessage,
      preferredStyle: .alert)
    languagePrompt.addTextField(configurationHandler: addTextField)
    languagePrompt.addAction(
      UIAlertAction(title: "Cancel", style: .default, handler: nil))
    languagePrompt.addAction(
      UIAlertAction(title: "OK", style: .default, handler: languageEntered))
    present(languagePrompt, animated: true, completion: nil)

  }

  // Handler when user clicks "OK" on the language pop-up
  func languageEntered(_ alert: UIAlertAction!) {
    if languageInput!.text != nil {
      language = languageInput!.text!
    }
    setUpAdsLoader()
  }

  // Used to create the text field in the language pop-up.
  func addTextField(_ textField: UITextField!) {
    textField.placeholder = language as String
    languageInput = textField
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showVideo" {
      let indexPath: IndexPath! = tableView.indexPathForSelectedRow
      if indexPath != nil {
        let video = videos[indexPath.row] as! Video
        let headedTo = segue.destination as! VideoViewController
        headedTo.video = video
        headedTo.adsLoader = adsLoader
      }
    }
  }

  override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
    if tableView.indexPathForSelectedRow != nil {
      return true
    }
    return false
  }

  // Only allow one selection.
  @objc func numberOfSectionsInTableView(_ tableView: UITableView) -> NSInteger {
    return 1
  }

  // Returns the number of items to be presented in the table.
  @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return videos.count
  }

  @objc func tableView(
    _ tableView: UITableView,
    cellForRowAtIndexPath indexPath: IndexPath
  ) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(
        withIdentifier: "cell",
        for: indexPath) as! VideoTableViewCell
    let selectedVideo = videos[(indexPath as NSIndexPath).row] as! Video
    cell.populateWithVideo(selectedVideo)
    return cell
  }

}
