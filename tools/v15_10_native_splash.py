#!/usr/bin/env python3
"""Run only AFTER flutter create in GitHub Actions. No app IDs or keys changed."""
from pathlib import Path
import re,shutil,xml.etree.ElementTree as ET
root = Path(__file__).resolve().parents[1]
res = root / 'android/app/src/main/res'
if not res.exists():
    raise SystemExit('Android kaynaklari olusmamis: Flutter create adimini kontrol et')
assert (root/'native/v15_10_native_icon.png').is_file()
color_dir = res/'values'; color_dir.mkdir(exist_ok=True, parents=True)
# Android < 12 startup background; Android 12+ system icon theme follows values-v31.
color_resource = color_dir/'v15_10_colors.xml'
color_resource.write_text('''<?xml version="1.0" encoding="utf-8"?>
<resources><color name="v15_10_launch_bg">#F2A9D2</color></resources>
''', encoding='utf-8')
icon_dir = res/'drawable-nodpi';icon_dir.mkdir(exist_ok=True,parents=True)
shutil.copy2(root/'native/v15_10_native_icon.png', icon_dir/'v15_10_native_icon.png')
launch_xml='''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
  <item android:drawable="@color/v15_10_launch_bg" />
  <item>
    <bitmap android:gravity="center" android:src="@drawable/v15_10_native_icon" />
  </item>
</layer-list>
'''
for folder in ('drawable','drawable-v21'):
    xml=res/folder/'launch_background.xml'
    xml.parent.mkdir(exist_ok=True,parents=True)
    xml.write_text(launch_xml,encoding='utf-8')
# Flutter may generate Android 12's styles.xml; retain any other themes.
v31 = res/'values-v31/styles.xml';v31.parent.mkdir(exist_ok=True,parents=True)
ANDROID_NS='http://schemas.android.com/apk/res/android'
if v31.exists():
    tree=ET.parse(v31)
    resource=tree.getroot()
else:
    resource=ET.Element('resources')
launch=next((e for e in resource.findall('style') if e.get('name')=='LaunchTheme'), None)
if launch is None:
    launch=ET.SubElement(resource,'style',{'name':'LaunchTheme','parent':'@android:style/Theme.Light.NoTitleBar'})
for key,value in {
    'android:windowBackground':'@drawable/launch_background',
    'android:windowSplashScreenBackground':'@color/v15_10_launch_bg',
    'android:windowSplashScreenAnimatedIcon':'@drawable/v15_10_native_icon',
    'android:windowLightStatusBar':'false',
    'android:windowLightNavigationBar':'false',
}.items():
    node=next((e for e in launch.findall('item') if e.get('name')==key),None)
    if node is None: node=ET.SubElement(launch,'item',{'name':key})
    node.text=value
ET.indent(resource,space='    ')
ET.ElementTree(resource).write(v31,encoding='utf-8',xml_declaration=True)
print('V15.10 Android sistem acilisi pembe tema ve seker ikonu olarak ayarlandi')
