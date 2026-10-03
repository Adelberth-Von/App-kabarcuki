"""Render the original, code-defined pixel chat icon for both platforms."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parent.parent
rects=[(3,4,18,14,'#7463C3'),(1,6,22,10,'#7463C3'),(5,18,4,3,'#7463C3'),(5,21,2,2,'#7463C3'),(5,7,14,8,'#F8F3EC'),(7,10,2,2,'#7463C3'),(11,10,2,2,'#7463C3'),(15,10,2,2,'#CE7C9C')]
def render(size):
    im=Image.new('RGB',(size,size),'#F1EDF9');d=ImageDraw.Draw(im);u=size/36;pad=6*u
    for x,y,w,h,c in rects:d.rectangle((round(pad+x*u),round(pad+y*u),round(pad+(x+w)*u)-1,round(pad+(y+h)*u)-1),fill=c)
    return im
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    render(size).save(root/f'crossplatform/android/app/src/main/res/mipmap-{density}/ic_launcher.png')
folder=root/'crossplatform/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for item in json.loads((folder/'Contents.json').read_text())['images']:
    if 'filename' in item:render(round(float(item['size'].split('x')[0])*float(item['scale'].replace('x','')))).save(folder/item['filename'])
render(512).save(root/'screenshots/abc-icon.png')
