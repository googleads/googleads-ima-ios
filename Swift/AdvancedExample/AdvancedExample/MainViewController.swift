import UIKit

import GoogleInteractiveMediaAds

class MainViewController: UIViewController {

  // Handle to TableView.
  @IBOutlet var tableView: UITableView!

  // Input field for language pop-up.
  @IBOutlet weak var languageInput: UITextField?

  // Storage point for videos.
  var videos: NSArray!
  var adsLoader: IMAAdsLoader?
  var language: NSString!

  // Set up the app.
  override func viewDidLoad() {
    super.viewDidLoad()
    language = "en"
    initVideos()
    setUpAdsLoader()

    // For PiP.
    do {
      try AVAudioSession.sharedInstance().setActive(true);
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback);
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
        tag:kAdRulesPodsTag),
      Video(
        title: "VMAP Pods",
        thumbnail :androidThumbnail,
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
        tag:kAdSenseTag),
      Video(
        title: "Custom",
        thumbnail: androidThumbnail,
        video: kAndroidContentPath,
        tag: "custom")
    ]
  }

  // Initialize AdsLoader.
  func setUpAdsLoader() {
    if (adsLoader != nil) {
      adsLoader = nil
    }
    let settings = IMASettings()
    settings.language = language as String
    settings.enableBackgroundPlayback = true;
    adsLoader = IMAAdsLoader(settings: settings)
  }

  // Show the language pop-up.
  @IBAction func onLanguageClicked() {
    let alertMessage = "NOTE: This will only change the ad UI language. The language elsewhere" +
        " in the app will remain in English. Language must be formated as a canonicalized IETF" +
        " BCP 47 language identifier such as would be returned by [NSLocale preferredLanguages]," +
        " e.g. \"en\", \"es\", etc.";

    let languagePrompt = UIAlertController(
        title: "Language",
        message: alertMessage,
        preferredStyle: UIAlertControllerStyle.Alert)
    languagePrompt.addTextFieldWithConfigurationHandler(addTextField)
    languagePrompt.addAction(
        UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
    languagePrompt.addAction(
        UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: languageEntered))
    presentViewController(languagePrompt, animated: true, completion: nil)

  }

  // Handler when user clicks "OK" on the language pop-up
  func languageEntered(alert: UIAlertAction!) {
    language = languageInput!.text
    setUpAdsLoader()
  }

  // Used to create the text field in the language pop-up.
  func addTextField(textField: UITextField!) {
    textField.placeholder = language as String
    languageInput = textField
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if (segue.identifier == "showVideo") {
      let indexPath: NSIndexPath! = tableView.indexPathForSelectedRow
      if (indexPath != nil) {
        let video = videos[indexPath.row] as! Video
        let headedTo = segue.destinationViewController as! VideoViewController
        headedTo.video = video
        headedTo.adsLoader = adsLoader
      }
    }
  }

  override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
    if (tableView.indexPathForSelectedRow != nil) {
      return true
    }
    return false
  }

  // Only allow one selection.
  func numberOfSectionsInTableView(tableView: UITableView) -> NSInteger {
    return 1;
  }

  // Returns the number of items to be presented in the table.
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return videos.count
  }

  func tableView(
      tableView: UITableView,
      cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(
        "cell",
        forIndexPath: indexPath) as! VideoTableViewCell
    let selectedVideo = videos[indexPath.row] as! Video
    cell.populateWithVideo(selectedVideo)
    return cell
  }

}

