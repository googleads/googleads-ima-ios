//
//  Constants.swift
//  AdvancedExample
//
//  Created by Shawn Busolits on 5/6/15.
//

import Foundation

// DFP content path
let kDFPContentPath = "http://rmcdn.2mdn.net/Demo/html5/output.mp4";

// Android content path
let kAndroidContentPath = "https://s0.2mdn.net/instream/videoplayer/media/android.mp4";

// Big buck bunny content path
let kBigBuckBunnyContentPath = "http://googleimadev-vh.akamaihd.net/i/big_buck_bunny/" +
    "bbb-,480p,720p,1080p,.mov.csmil/master.m3u8";

// Bip bop content path
let kBipBopContentPath = "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";

// Standard pre-roll
let kPrerollTag = "http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&" +
    "iu=%2F6062%2Fhanna_MA_group%2Fvideo_comp_app&ciu_szs=&impl=s&gdfp_req=1&env=vp&" +
    "output=xml_vast2&unviewed_position_start=1&m_ast=vast&url=[referrer_url]&" +
    "correlator=[timestamp]";

// Skippable
let kSkippableTag = "http://pubads.g.doubleclick.net/gampad/ads?sz=640x360&" +
    "iu=/6062/iab_vast_samples/skippable&ciu_szs=300x250,728x90&impl=s&gdfp_req=1&env=vp&" +
    "output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]";

// Post-roll
let kPostrollTag = "http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&" +
    "iu=%2F3510761%2FadRulesSampleTags&ciu_szs=160x600%2C300x250%2C728x90&" +
    "cust_params=adrule%3Dpostrollonly&impl=s&gdfp_req=1&env=vp&ad_rule=1&vid=47570401&cmsid=481&" +
    "output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&correlator=[timestamp]";

// Ad rues
let kAdRulesTag = "http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&" +
    "iu=%2F3510761%2FadRulesSampleTags&ciu_szs=160x600%2C300x250%2C728x90&" +
    "cust_params=adrule%3Dpremidpostnopod&impl=s&gdfp_req=1&env=vp&ad_rule=1&vid=47570401&" +
    "cmsid=481&output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&" +
    "correlator=[timestamp]";

// Ad rules pods
let kAdRulesPodsTag = "http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&" +
    "iu=%2F3510761%2FadRulesSampleTags&ciu_szs=160x600%2C300x250%2C728x90&" +
    "cust_params=adrule%3Dpremidpostwithpod&impl=s&gdfp_req=1&env=vp&ad_rule=1&vid=47570401&" +
    "cmsid=481&output=xml_vast2&unviewed_position_start=1&url=[referrer_url]&" +
    "correlator=[timestamp]";

// VMAP pods
let kVMAPPodsTag = "http://pubads.g.doubleclick.net/gampad/ads?sz=640x480&" +
    "iu=%2F15018773%2Feverything2&ciu_szs=300x250%2C468x60%2C728x90&impl=s&gdfp_req=1&env=vp&" +
    "output=xml_vmap1&unviewed_position_start=1url=[referrer_url]&correlator=[timestamp]&" +
    "cmsid=133&vid=10XWSh7W4so&ad_rule=1";

// Wrapper
let kWrapperTag = "http://pubads.g.doubleclick.net/gampad/ads?sz=400x300&" +
    "iu=%2F6062%2Fhanna_MA_group%2Fwrapper_with_comp&ciu_szs=728x90&impl=s&gdfp_req=1&env=vp&" +
    "output=xml_vast2&unviewed_position_start=1&m_ast=vast&url=[referrer_url]&" +
    "correlator=[timestamp]";

// AdSense
let kAdSenseTag = "http://googleads.g.doubleclick.net/pagead/ads?client=ca-video-afvtest&" +
    "ad_type=video";
