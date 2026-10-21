#!/usr/bin/env python3
# V15.12 startup theme - bounded icon sizing
from pathlib import Path
import shutil
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
res = root / 'android/app/src/main/res'
if not res.is_dir():
    raise SystemExit('Android res klasoru yok: once flutter create calismali.')

color_name = 'v15_12_launch_bg'
icon12 = 'v15_12_system_icon'
iconold = 'v15_12_legacy_icon'
color_path = res/'values/v15_12_colors.xml'
color_path.parent.mkdir(parents=True, exist_ok=True)
color_path.write_text(f'''<?xml version="1.0" encoding="utf-8"?>
<resources><color name="{color_name}">#8AD6F4</color></resources>
''',encoding='utf-8')
for src_name, drawable_name in [('v15_12_system_icon.png',icon12),
                                ('v15_12_legacy_icon.png',iconold)]:
    src = root/'native'/src_name
    if not src.is_file():
        raise SystemExit('Eksik icon: '+str(src))
    tgt = res/'drawable-nodpi'/(drawable_name+'.png')
    tgt.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src,tgt)

# Pre-Android12 theme has a small crisp candy badge against the sky blue.
launch_bg=f'''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
  <item android:drawable="@color/{color_name}"/>
  <item><bitmap android:gravity="center" android:src="@drawable/{iconold}"/></item>
</layer-list>
'''
for folder in ('drawable','drawable-v21'):
    f=res/folder/'launch_background.xml'
    f.parent.mkdir(parents=True,exist_ok=True)
    f.write_text(launch_bg,encoding='utf-8')

v31 = res/'values-v31/styles.xml'
v31.parent.mkdir(parents=True,exist_ok=True)
resource = ET.parse(v31).getroot() if v31.is_file() else ET.Element('resources')
launch = next((e for e in resource.findall('style') if e.get('name')=='LaunchTheme'),None)
if launch is None:
    launch=ET.SubElement(resource,'style',{'name':'LaunchTheme',
      'parent':'@android:style/Theme.Light.NoTitleBar'})
updates={
  'android:windowBackground':'@drawable/launch_background',
  'android:windowSplashScreenBackground':f'@color/{color_name}',
  'android:windowSplashScreenAnimatedIcon':f'@drawable/{icon12}',
  'android:windowLightStatusBar':'false',
  'android:windowLightNavigationBar':'false',
}
for key,value in updates.items():
    item=next((i for i in launch.findall('item') if i.get('name')==key),None)
    if item is None:
        item=ET.SubElement(launch,'item',{'name':key})
    item.text=value
ET.indent(resource,space='    ')
ET.ElementTree(resource).write(v31,encoding='utf-8',xml_declaration=True)
print('Android acilis: mavi fon, ufak temiz seker amblemi.')
