import 'dart:io';
import 'dart:ui' as ui;
import 'package:abc/model.dart';
import 'package:abc/pixels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class EmptyBackend extends Backend {
  @override Future<Map<String,dynamic>> invoke(String method,[Map<String,dynamic> args=const {}])async=>{};
}
void main(){
  test('meal routing respects customized local windows and exclusive end boundaries',(){
    final model=AppModel(EmptyBackend())..snapshot={'state':{'windows':[5,10,11,14,17,22]}};
    for(final entry in {4:'Makan',5:'Sarapan',9:'Sarapan',10:'Makan',11:'Makan siang',14:'Makan',18:'Makan malam',22:'Makan'}.entries){
      expect(model.mealNow(DateTime(2026,10,3,entry.key)),entry.value);
    }
    model.dispose();
  });
  testWidgets('all 24 action, theme and time scenes differ; action motion changes pixels',(tester)async{
    tester.view.physicalSize=const Size(500,300);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final hashes=<int>{};
    for(final together in [false,true]){
      for(final hour in [8,12,16,20]){
        for(final action in ['outside','home','meal']){
          final key=GlobalKey();
          await tester.pumpWidget(MaterialApp(home:Center(child:RepaintBoundary(key:key,child:SizedBox(width:336,height:114,child:PixelSky(action:action,together:together,at:DateTime(2026,10,3,hour),animate:true))))));
          await tester.pump();
          Future<int> capture(String suffix)async{
            final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image=boundary.toImageSync();
            final hash=await tester.runAsync(()async{
              final raw=(await image.toByteData())!;
              if(const bool.fromEnvironment('QA_ART')){
                final png=(await image.toByteData(format:ui.ImageByteFormat.png))!;
                final folder=Directory('qa-screenshots/scenes');await folder.create(recursive:true);
                await File('${folder.path}/${together?'seirama':'default'}-$action-$hour-$suffix.png').writeAsBytes(png.buffer.asUint8List());
              }
              return Object.hashAll(raw.buffer.asUint8List());
            });image.dispose();return hash!;
          }
          final first=await capture('still');expect(hashes.add(first),true,reason:'$together/$hour/$action must be distinct');
          await tester.pump(const Duration(seconds:1));final next=await capture('motion');expect(next,isNot(first));
        }
      }
    }
    await tester.pumpWidget(const SizedBox());await tester.pump();
  });
}
