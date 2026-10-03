from pathlib import Path
import plistlib
p=Path(__file__).resolve().parent.parent/'crossplatform/ios/Runner/Info.plist'
with p.open('rb') as f:info=plistlib.load(f)
info.update(CFBundleDisplayName='abc',KabarKeychainGroup='$(AppIdentifierPrefix)id.kabar.shared',NSLocationWhenInUseUsageDescription='abc shares a location only when you confirm an update, with the people holding your pairing code.',CFBundleURLTypes=[{'CFBundleURLSchemes':['kabar']}])
with p.open('wb') as f:plistlib.dump(info,f)
