#!/usr/bin/env python3
"""Android 12+ native splash + pre-12 launch styles. Visual-only update."""
from pathlib import Path
import shutil
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
res = root / 'android/app/src/main/res'
if not res.is_dir():
    raise SystemExit('Android resources missing. Flutter create must run first.')

# Android 12+ system splash is OS-controlled: a solid color with centered icon.
color_name = 'v15_10_launch_bg'
native_icon = 'v15_11_native_icon'
color = '#93D7F7'  # matches the opening illustration sky, no more blank pink.
color_path = res/'values/v15_10_colors.xml'
color_path.parent.mkdir(parents=True, exist_ok=True)
color_path.write_text(f'''<?xml version="1.0" encoding="utf-8"?>
<resources><color name="{color_name}">{color}</color></resources>
''', encoding='utf-8')
icon_path = root/f'native/{native_icon}.png'
if not icon_path.is_file():
    raise SystemExit('Native candy emblem asset missing: '+str(icon_path))
target = res/'drawable-nodpi'/f'{native_icon}.png'
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(icon_path, target)
launch_xml=f'''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
  <item android:drawable="@color/{color_name}"/>
  <item><bitmap android:gravity="center" android:src="@drawable/{native_icon}"/></item>
</layer-list>
'''
for folder in ('drawable','drawable-v21'):
    output = res/folder/'launch_background.xml'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(launch_xml, encoding='utf-8')

v31 = res/'values-v31/styles.xml'
v31.parent.mkdir(parents=True, exist_ok=True)
if v31.is_file():
    resource = ET.parse(v31).getroot()
else:
    resource = ET.Element('resources')
launch = next((e for e in resource.findall('style') if e.get('name')=='LaunchTheme'), None)
if launch is None:
    launch = ET.SubElement(resource,'style',{'name':'LaunchTheme','parent':'@android:style/Theme.Light.NoTitleBar'})
updates = {
  'android:windowBackground':'@drawable/launch_background',
  'android:windowSplashScreenBackground':f'@color/{color_name}',
  'android:windowSplashScreenAnimatedIcon':f'@drawable/{native_icon}',
  'android:windowLightStatusBar':'false',
  'android:windowLightNavigationBar':'false',
}
for key,value in updates.items():
    item = next((it for it in launch.findall('item') if it.get('name')==key),None)
    if item is None:
        item = ET.SubElement(launch,'item',{'name':key})
    item.text=value
ET.indent(resource,space='    ')
ET.ElementTree(resource).write(v31,encoding='utf-8',xml_declaration=True)
print('V15.11: native sky-blue splash and real candy logo enabled.')
