#import <Foundation/Foundation.h>

// DFP content path
static NSString *const kDFPContentPath = @"http://rmcdn.2mdn.net/Demo/html5/output.mp4";

// Android content path
static NSString *const kAndroidContentPath =
    @"https://s0.2mdn.net/instream/videoplayer/media/android.mp4";

// Big buck bunny content path
static NSString *const kBigBuckBunnyContentPath =
    @"http://googleimadev-vh.akamaihd.net/i/big_buck_bunny/"
    @"bbb-,480p,720p,1080p,.mov.csmil/master.m3u8";

// Bip bop content path
static NSString *const kBipBopContentPath =
    @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";

// Standard pre-roll
static NSString *const kPrerollTag = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
    @"iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&"
    @"output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&"
    @"correlator=";

// Skippable
static NSString *const kSkippableTag = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
    @"iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&"
    @"output=vast&unviewed_position_start=1&"
    @"cust_params=deployment%3Ddevsite%26sample_ct%3Dskippablelinear&correlator=";

// Post-roll
static NSString *const kPostrollTag = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
    @"iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&"
    @"output=vmap&unviewed_position_start=1&"
    @"cust_params=deployment%3Ddevsite%26sample_ar%3Dpostonly&cmsid=496&vid=short_onecue&"
    @"correlator=";

// Ad rues
static NSString *const kAdRulesTag = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
    @"iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&"
    @"output=vast&unviewed_position_start=1&"
    @"cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&"
    @"correlator=";

// Ad rules pods
static NSString *const kAdRulesPodsTag = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
    @"iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&"
    @"output=vast&unviewed_position_start=1&"
    @"cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpostpod&cmsid=496&vid=short_onecue&"
    @"correlator=";

// VMAP pods
static NSString *const kVMAPPodsTag = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
    @"iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&"
    @"output=vmap&unviewed_position_start=1&"
    @"cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpostpod&cmsid=496&vid=short_onecue&"
    @"correlator=";

// Wrapper
static NSString *const kWrapperTag = @"http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
    @"iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&"
    @"output=vast&unviewed_position_start=1&"
    @"cust_params=deployment%3Ddevsite%26sample_ct%3Dredirectlinear&correlator=";

// AdSense
static NSString *const kAdSenseTag =
    @"http://googleads.g.doubleclick.net/pagead/ads?client=ca-video-afvtest&ad_type=video";
