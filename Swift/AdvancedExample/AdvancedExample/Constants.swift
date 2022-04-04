import Foundation

// DFP content path
let kDFPContentPath = "https://storage.googleapis.com/gvabox/media/samples/stock.mp4"

// Android content path
let kAndroidContentPath = "https://storage.googleapis.com/gvabox/media/samples/android.mp4"

// Big buck bunny content path
let kBigBuckBunnyContentPath =
  "http://googleimadev-vh.akamaihd.net/i/big_buck_bunny/"
  + "bbb-,480p,720p,1080p,.mov.csmil/master.m3u8"

// Bip bop content path
let kBipBopContentPath = "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"

// Standard pre-roll
let kPrerollTag =
  "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
  + "single_ad_samples&sz=640x480&cust_params=sample_ct%3Dlinear&ciu_szs=300x250%2C728x90&"
  + "gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator="

// Skippable
let kSkippableTag =
  "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
  + "single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&"
  + "output=vast&unviewed_position_start=1&env=vp&impl=s&correlator="

// Post-roll
let kPostrollTag =
  "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
  + "vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpostonly&ciu_szs=300x250&"
  + "gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&correlator="

// Ad rules
let kAdRulesTag =
  "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
  + "vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpremidpost&ciu_szs=300x250&"
  + "gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496&"
  + "vid=short_onecue&correlator="

// Ad rules pods
let kAdRulesPodsTag =
  "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
  + "vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpremidpostpod&ciu_szs=300x250&"
  + "gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496&"
  + "vid=short_onecue&correlator="

// VMAP pods
let kVMAPPodsTag =
  "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
  + "vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpremidpostpod&ciu_szs=300x250&"
  + "gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496&"
  + "vid=short_onecue&correlator="

// Wrapper
let kWrapperTag =
  "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/"
  + "single_ad_samples&sz=640x480&cust_params=sample_ct%3Dredirectlinear&"
  + "ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&"
  + "env=vp&impl=s&correlator="

// AdSense
let kAdSenseTag =
  "http://googleads.g.doubleclick.net/pagead/ads?client=ca-video-afvtest&ad_type=video"
